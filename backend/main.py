from fastapi import FastAPI, File, UploadFile
from fastapi.responses import JSONResponse
from typing import Optional
import whisper
import tempfile
import os
from parser import parse_voice_command
from inventory import update_inventory, init_db, get_all_items

# Image detection imports
from PIL import Image
import io
import torch
from ultralytics import YOLO

import numpy as np

app = FastAPI()

# Load Whisper model on startup
print("Loading Whisper model...")
whisper_model = whisper.load_model("base")
print("Whisper model loaded!")

# Initialize database
init_db()

# ===== IMAGE DETECTION SETUP =====
# Primary image detection model: YOLOv8n (COCO)
yolo_model = None
FOOD_KEYWORDS = {
    "apple", "banana", "orange", "tomato", "carrot", "potato", "onion",
    "garlic", "bread", "milk", "cheese", "egg", "chicken", "fish", "beef",
    "lettuce", "cucumber", "broccoli", "strawberry", "grapes", "watermelon",
    "lemon", "lime", "avocado", "mushroom", "yogurt", "juice", "butter",
    "cream", "pasta", "rice", "corn", "peas", "beans", "celery", "sausage",
    "bacon", "ham", "turkey", "pork", "salmon", "tuna", "shrimp",
    "sandwich", "hot dog", "pizza", "donut", "cake", "bowl", "cup", "bottle"
}

try:
    print("Loading YOLOv8 for image detection...")
    yolo_model = YOLO("yolov8n.pt")
    print("YOLOv8 loaded successfully!")
except Exception as e:
    print(f"Warning: Could not load YOLOv8: {e}")
    print("Image detection will use fallback methods")

# Alternative food classification model
classification_model = None
image_processor = None
try:
    print("Loading food classification model...")
    from transformers import AutoImageProcessor, AutoModelForImageClassification
    image_processor = AutoImageProcessor.from_pretrained("nateraw/food")
    classification_model = AutoModelForImageClassification.from_pretrained("nateraw/food")
    print("Food classification model loaded!")
except Exception as e:
    print(f"Warning: Could not load food classification model: {e}")

# ===== EXISTING ENDPOINTS =====

@app.get("/")
def root():
    return {"message": "Kitchen Inventory Server - Running with Image Detection"}

@app.get("/inventory")
def get_inventory():
    """Get all inventory items"""
    try:
        items = get_all_items()
        return {"items": items}
    except Exception as e:
        return JSONResponse(
            status_code=500,
            content={"error": str(e)}
        )

@app.post("/voice")
def process_voice_text(text: str, location: Optional[str] = None):
    """
    Process text-based voice command
    Location is optional - will auto-classify if not provided
    """
    try:
        commands = parse_voice_command(text)
        updates = []
        
        for cmd in commands:
            result = update_inventory(
                product=cmd['product'],
                quantity=cmd['quantity'],
                action=cmd['action'],
                location=location  # Pass None to auto-classify
            )
            updates.append(result)
        
        return {
            "transcription": text,
            "commands": commands,
            "updates": updates
        }
    except Exception as e:
        return JSONResponse(
            status_code=500,
            content={"error": str(e)}
        )

@app.post("/voice-audio")
async def process_voice_audio(file: UploadFile = File(...), location: Optional[str] = None):
    """
    Process audio file with Whisper transcription
    Location is optional - will auto-classify if not provided
    """
    temp_path = None
    try:
        # Save uploaded file temporarily
        with tempfile.NamedTemporaryFile(delete=False, suffix=".aac") as temp_file:
            content = await file.read()
            temp_file.write(content)
            temp_path = temp_file.name
        
        print(f"Transcribing audio file: {temp_path}")
        
        # Transcribe with Whisper
        result = whisper_model.transcribe(temp_path)
        transcription = result["text"]
        
        print(f"Transcription: {transcription}")
        
        # Parse commands
        commands = parse_voice_command(transcription)
        
        # Execute commands (auto-classify location if not provided)
        updates = []
        for cmd in commands:
            update_result = update_inventory(
                product=cmd['product'],
                quantity=cmd['quantity'],
                action=cmd['action'],
                location=location  # Pass None to auto-classify
            )
            updates.append(update_result)
        
        return {
            "transcription": transcription,
            "commands": commands,
            "updates": updates
        }
    
    except Exception as e:
        print(f"Error processing audio: {e}")
        return JSONResponse(
            status_code=500,
            content={"error": str(e)}
        )
    
    finally:
        # Clean up temp file
        if temp_path and os.path.exists(temp_path):
            try:
                os.remove(temp_path)
            except:
                pass

# ===== NEW IMAGE DETECTION ENDPOINTS =====

@app.post("/detect-image")
async def detect_image(file: UploadFile = File(...)):
    """
    Detect food items in uploaded image using AI
    Returns list of detected items with confidence scores
    """
    try:
        print(f"Received image for detection: {file.filename}")
        
        # Read and open image
        contents = await file.read()
        image = Image.open(io.BytesIO(contents)).convert("RGB")
        print(f"Image size: {image.size}")
        
        detected_items = []
        detection_method = "none"
        
        # Method 1: YOLOv8 detection (primary)
        if yolo_model:
            print("Using YOLOv8 for detection...")
            detection_method = "yolov8"

            results = yolo_model(image, verbose=False)

            seen = set()
            for result in results:
                for box in result.boxes:
                    confidence = float(box.conf[0])
                    if confidence < 0.25:
                        continue
                    class_id = int(box.cls[0])
                    label = result.names[class_id]
                    if label in seen:
                        continue
                    seen.add(label)
                    label_lower = label.lower()
                    category = "food" if any(kw in label_lower for kw in FOOD_KEYWORDS) else "general"
                    detected_items.append({
                        "name": label,
                        "label": label,
                        "confidence": confidence,
                        "category": category
                    })
                    print(f"  - {label}: {confidence:.2%}")
        
        # Method 2: Food classification model (fallback)
        elif classification_model and image_processor:
            print("Using food classification model...")
            detection_method = "food_classifier"
            
            inputs = image_processor(images=image, return_tensors="pt")
            
            with torch.no_grad():
                outputs = classification_model(**inputs)
                logits = outputs.logits
                probs = torch.nn.functional.softmax(logits, dim=-1)
            
            # Get top 10 predictions
            top_probs, top_indices = torch.topk(probs[0], k=10)
            
            for prob, idx in zip(top_probs, top_indices):
                confidence = float(prob.item())
                if confidence > 0.05:
                    label = classification_model.config.id2label[idx.item()]
                    detected_items.append({
                        "name": label,
                        "label": label,
                        "confidence": confidence,
                        "category": "food"
                    })
                    print(f"  - {label}: {confidence:.2%}")
        
        # Method 3: Basic color detection (last resort fallback)
        else:
            print("Using basic color detection (no AI models loaded)...")
            detection_method = "basic_color"
            detected_items = _basic_color_detection(np.array(image))
        
        # Sort by confidence
        detected_items.sort(key=lambda x: x['confidence'], reverse=True)
        
        print(f"Total items detected: {len(detected_items)}")
        print(f"Detection method: {detection_method}")
        
        return JSONResponse(content={
            "status": "success",
            "items": detected_items[:5],  # Return top 5
            "method": detection_method,
            "total_detected": len(detected_items)
        })
        
    except Exception as e:
        print(f"Error in image detection: {e}")
        import traceback
        traceback.print_exc()
        return JSONResponse(
            status_code=500,
            content={
                "status": "error",
                "message": str(e),
                "items": []
            }
        )


def _basic_color_detection(img_array):
    """
    Basic color-based detection as fallback when no AI models available
    """
    try:
        import cv2
        detected = []
        
        # Convert to HSV for better color detection
        hsv = cv2.cvtColor(img_array, cv2.COLOR_RGB2HSV)
        
        # Define color ranges for common fruits/vegetables
        color_items = {
            "red apple or tomato": ([0, 50, 50], [10, 255, 255]),
            "orange or carrot": ([10, 50, 50], [25, 255, 255]),
            "banana or lemon": ([25, 50, 50], [35, 255, 255]),
            "green vegetable": ([35, 50, 50], [85, 255, 255]),
        }
        
        total_pixels = img_array.shape[0] * img_array.shape[1]
        
        for item_name, (lower, upper) in color_items.items():
            lower = np.array(lower)
            upper = np.array(upper)
            mask = cv2.inRange(hsv, lower, upper)
            color_pixels = cv2.countNonZero(mask)
            
            if color_pixels > total_pixels * 0.03:  # At least 3% of image
                confidence = min(color_pixels / total_pixels * 3, 0.7)
                detected.append({
                    "name": item_name,
                    "label": item_name,
                    "confidence": confidence,
                    "category": "produce"
                })
        
        return detected
    except Exception as e:
        print(f"Basic detection error: {e}")
        return [{
            "name": "unknown item",
            "label": "unknown item",
            "confidence": 0.3,
            "category": "general"
        }]


@app.post("/add-item")
def add_item(name: str, location: str, quantity: int = 1):
    """
    Add a single item to inventory by name, location, and quantity.
    Uses the same expiry and category logic as voice commands.
    """
    try:
        result = update_inventory(
            product=name,
            quantity=quantity,
            action="add",
            location=location
        )
        return result
    except Exception as e:
        return JSONResponse(
            status_code=500,
            content={"error": str(e)}
        )


@app.get("/detection-status")
def detection_status():
    """
    Check which detection methods are available
    """
    return {
        "yolo_available": yolo_model is not None,
        "food_classifier_available": classification_model is not None,
        "fallback_available": True,
        "recommended_method": "yolov8" if yolo_model else "food_classifier" if classification_model else "basic"
    }


if __name__ == "__main__":
    import uvicorn
    print("\n" + "="*60)
    print("🍎 Kitchen Inventory Server Starting...")
    print("="*60)
    print(f"✓ Whisper model loaded")
    print(f"✓ YOLOv8 model: {'loaded' if yolo_model else 'not available'}")
    print(f"✓ Food classifier: {'loaded' if classification_model else 'not available'}")
    print("="*60 + "\n")
    uvicorn.run(app, host="0.0.0.0", port=8000)