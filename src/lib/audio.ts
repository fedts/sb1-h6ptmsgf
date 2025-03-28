// Emergency sound system using Web Audio API
export class EmergencySound {
  private audioContext: AudioContext | null = null;
  private oscillator: OscillatorNode | null = null;
  private gainNode: GainNode | null = null;
  private isPlaying: boolean = false;

  constructor() {
    // Create AudioContext on first user interaction
    const createContext = () => {
      if (!this.audioContext) {
        this.audioContext = new AudioContext();
        document.removeEventListener('click', createContext);
      }
    };
    document.addEventListener('click', createContext);
  }

  start() {
    if (this.isPlaying) return;

    try {
      if (!this.audioContext) {
        this.audioContext = new AudioContext();
      }

      // Stop any existing sound
      this.stop();

      // Create oscillator for the beeping sound
      this.oscillator = this.audioContext.createOscillator();
      this.gainNode = this.audioContext.createGain();

      // Configure oscillator for a more urgent sound
      this.oscillator.type = 'square'; // More harsh sound than sine
      this.oscillator.frequency.setValueAtTime(880, this.audioContext.currentTime); // Higher pitch (A5)

      // Configure gain node for louder volume
      this.gainNode.gain.setValueAtTime(0, this.audioContext.currentTime);

      // Connect nodes
      this.oscillator.connect(this.gainNode);
      this.gainNode.connect(this.audioContext.destination);

      // Start oscillator
      this.oscillator.start();
      this.isPlaying = true;

      // Create beeping pattern
      this.createBeepingPattern();
    } catch (error) {
      console.error('Error starting emergency sound:', error);
    }
  }

  private createBeepingPattern() {
    if (!this.audioContext || !this.gainNode) return;

    const beepLength = 0.2; // Shorter beeps
    const beepInterval = 0.4; // Faster intervals
    const now = this.audioContext.currentTime;

    // Schedule beeps for the next minute (can be stopped earlier)
    for (let i = 0; i < 120; i++) {
      const startTime = now + i * beepInterval;
      const endTime = startTime + beepLength;
      
      // Louder volume and sharp attack
      this.gainNode.gain.setValueAtTime(0, startTime);
      this.gainNode.gain.linearRampToValueAtTime(0.5, startTime + 0.01); // Quick ramp up
      this.gainNode.gain.setValueAtTime(0.5, endTime - 0.01); // Hold
      this.gainNode.gain.linearRampToValueAtTime(0, endTime); // Quick ramp down

      // Frequency modulation for more urgency
      if (this.oscillator) {
        this.oscillator.frequency.setValueAtTime(880, startTime); // A5
        this.oscillator.frequency.setValueAtTime(988, startTime + beepLength / 2); // B5
      }
    }
  }

  stop() {
    if (!this.isPlaying) return;

    try {
      if (this.oscillator) {
        this.oscillator.stop();
        this.oscillator.disconnect();
        this.oscillator = null;
      }
      if (this.gainNode) {
        this.gainNode.disconnect();
        this.gainNode = null;
      }
      this.isPlaying = false;
    } catch (error) {
      console.error('Error stopping emergency sound:', error);
    }
  }
}