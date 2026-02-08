// Web Audio API für Solfeggio Frequenzen
class FrequencyPlayer {
  constructor() {
    this.audioContext = null;
    this.oscillator = null;
    this.gainNode = null;
    this.isPlaying = false;
    this.currentFrequency = null;
  }

  init() {
    if (!this.audioContext) {
      this.audioContext = new (window.AudioContext || window.webkitAudioContext)();
    }
  }

  play(frequency) {
    this.stop(); // Stop previous if playing
    
    this.init();
    
    // Create oscillator (sine wave for pure tone)
    this.oscillator = this.audioContext.createOscillator();
    this.oscillator.type = 'sine';
    this.oscillator.frequency.setValueAtTime(frequency, this.audioContext.currentTime);
    
    // Create gain node for volume control
    this.gainNode = this.audioContext.createGain();
    this.gainNode.gain.setValueAtTime(0.3, this.audioContext.currentTime); // 30% volume
    
    // Connect nodes
    this.oscillator.connect(this.gainNode);
    this.gainNode.connect(this.audioContext.destination);
    
    // Start playing
    this.oscillator.start();
    this.isPlaying = true;
    this.currentFrequency = frequency;
    
    console.log('🎵 Playing frequency:', frequency, 'Hz');
  }

  stop() {
    if (this.oscillator) {
      try {
        this.oscillator.stop();
        this.oscillator.disconnect();
      } catch (e) {
        // Ignore if already stopped
      }
      this.oscillator = null;
    }
    if (this.gainNode) {
      this.gainNode.disconnect();
      this.gainNode = null;
    }
    this.isPlaying = false;
    this.currentFrequency = null;
    console.log('🔇 Stopped playing');
  }

  setVolume(volume) {
    if (this.gainNode) {
      this.gainNode.gain.setValueAtTime(volume, this.audioContext.currentTime);
    }
  }
}

// Global player instance
window.frequencyPlayer = new FrequencyPlayer();

// Flutter-JavaScript Bridge Functions
window.playFrequency = function(frequency) {
  window.frequencyPlayer.play(parseFloat(frequency));
};

window.stopFrequency = function() {
  window.frequencyPlayer.stop();
};

window.setFrequencyVolume = function(volume) {
  window.frequencyPlayer.setVolume(parseFloat(volume));
};

console.log('✅ Frequency Player loaded!');
