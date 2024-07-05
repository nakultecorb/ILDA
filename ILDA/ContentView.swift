//
//  ContentView.swift
//  ILDA
//
//  Created by Nakul Sharma on 25/06/24.
//

import SwiftUI
import AVFAudio

struct ContentView: View {
    @State private var max: Double = 0.7
    @State private var min: Double = 0.3
    @State private var frequency: Double = 1.0
    @State private var isPlaying: Bool = false
    @State private var showingAlert = false
    @State private var selectedOption = "Ocean_waves"
    
    let options = ["Lullaby", "Ocean_waves", "Rain_sound", "Sweet_dreams"]
    
    let audioController = AudioController()
    
    var body: some View {
        VStack {
            
            //MARK: Dropdown/Picker at the top
            Picker("Select an option", selection: $selectedOption) {
                ForEach(options, id: \.self) { option in
                    Text(option).tag(option)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .padding()
            .onChange(of: selectedOption, { _, newValue in
                if self.isPlaying{
                    self.isPlaying = false
                    audioController.stopTone()
                    audioController.loadAudioFile(newValue)
                    audioController.setFrequency(frequency)
                    audioController.setMinMaxIntensity(min, max: max)
                    audioController.playTone()
                    self.isPlaying = true
                }
                else{
                    audioController.loadAudioFile(newValue)
                }
            })
            
            //MARK: Horizontal Sliders
            VStack {
                Text("=== Volume ===")
                //Min slider
                HStack {
                    Text("Min")
                    Slider(value: $min, in: 0.0...1.0, step: 0.1) { _ in
                        audioController.setMinMaxIntensity(min, max: max)
                    }
                    Text("\(Int(min * 10))/10")
                }
                .padding()
                //Max slider
                HStack {
                    Text("Max")
                    Slider(value: $max, in: 0.0...1.0, step: 0.1) { _ in
                        audioController.setMinMaxIntensity(min, max: max)
                    }
                    Text("\(Int(max * 10))/10")
                }
                .padding()
                
                //MARK: Play/Pause and Stop buttons
                VStack {
                    HStack {
                        Spacer()
                        Button(action: {
                            if max <= min{
                                showingAlert = true
                            }
                            else{
                                showingAlert = false
                            }
                            
                            if showingAlert{return}
                            
                            if isPlaying{
                                audioController.pauseTone()
                            }
                            else{
                                audioController.setFrequency(frequency)
                                audioController.setMinMaxIntensity(min, max: max)
                                audioController.playTone()
                            }
                            isPlaying = !isPlaying
                        }) {
                        Text(isPlaying ? "Pause" : "Play")
                            .padding(EdgeInsets(top: 10, leading: 40, bottom: 10, trailing: 40))
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                        .alert(isPresented: $showingAlert) {
                            Alert(title: Text("Important message"), message: Text("Max cann't be equal or smaller then Min"), dismissButton: .default(Text("Got it!")))
                        }
                        Spacer(minLength: 40)
                        Button(action: {
                            isPlaying = false
                            audioController.stopTone()
                        }) {
                            Text("Stop")
                                .padding(EdgeInsets(top: 10, leading: 40, bottom: 10, trailing: 40))
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        Spacer()
                    }
                    .padding()
                }
                .padding()
            }
            
            Spacer()
            
            //MARK: Flickering Frequency Value and Buttons at the bottom
            VStack{
                Text("Flickerring Frequency")
                    .fontWeight(.medium)
                    .padding()
                
                HStack {
                    Button(action: {
                        if frequency == 0.25{return}
                        frequency -= 0.25
                        audioController.setFrequency(frequency)
                    }) {
                        Text("<<<")
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    Spacer(minLength: 10)
                    Text(String(format: "%0.2f", frequency))
                        .padding(EdgeInsets(top: 15, leading: 30, bottom: 15, trailing: 30))
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .fontWeight(.medium)
                        .cornerRadius(8)
                    
                    Spacer(minLength: 10)
                    Button(action: {
                        if frequency == 4.0{return}
                        frequency += 0.25
                        audioController.setFrequency(frequency)
                    }) {
                        Text(">>>")
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
                .padding()
                .padding(EdgeInsets(top: 8, leading: 25, bottom: 8, trailing: 25))
            }
            .padding()
            
        }
        .onAppear() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                audioController.configureAudioSession()
                audioController.loadAudioFile(selectedOption)
            }
        }
        .onDisappear(){
            audioController.stopTone()
        }
    }
}

#Preview {
    ContentView()
}
