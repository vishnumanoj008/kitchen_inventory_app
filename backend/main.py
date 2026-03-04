from fastapi import FastAPI, File, UploadFile
from fastapi.responses import JSONResponse
from typing import Optional
import whisper
import tempfile
import os
from parser import parse_voice_command
from inventory import update_inventory, init_db, get_all_items

app = FastAPI()

# Load Whisper model on startup
print("Loading Whisper model...")
model = whisper.load_model("base")
print("Whisper model loaded!")

# Initialize database
init_db()

@app.get("/")
def root():
    return {"message": "Server works"}

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
        result = model.transcribe(temp_path)
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

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)