module audio_output (
    input clk,
    input reset,                   // Active-high reset
    input [13:0] switches,         // 13 switches for notes, 1 for octave selection
    output reg audio_out           // Output to JA[1]
);

    parameter SYSTEM_CLOCK = 100_000_000;
    parameter C4 = 262, CS4 = 277, D4 = 294, DS4 = 311;
    parameter E4 = 330, F4 = 349, FS4 = 370, G4 = 392;
    parameter GS4 = 415, A4 = 440, AS4 = 466, B4 = 494;
    parameter C5 = 524, CS5 = 554, D5 = 588, DS5 = 622;
    parameter E5 = 660, F5 = 698, FS5 = 740, G5 = 784;
    parameter GS5 = 831, A5 = 880, AS5 = 932, B5 = 988, C6 = 1047;

    // Half-periods for two octaves
    reg [31:0] half_period_lower [0:12];
    reg [31:0] half_period_upper [0:12];

    // Initialize half-period values
    initial begin
        half_period_lower[0] = SYSTEM_CLOCK / (2 * C4);
        half_period_lower[1] = SYSTEM_CLOCK / (2 * CS4);
        half_period_lower[2] = SYSTEM_CLOCK / (2 * D4);
        half_period_lower[3] = SYSTEM_CLOCK / (2 * DS4);
        half_period_lower[4] = SYSTEM_CLOCK / (2 * E4);
        half_period_lower[5] = SYSTEM_CLOCK / (2 * F4);
        half_period_lower[6] = SYSTEM_CLOCK / (2 * FS4);
        half_period_lower[7] = SYSTEM_CLOCK / (2 * G4);
        half_period_lower[8] = SYSTEM_CLOCK / (2 * GS4);
        half_period_lower[9] = SYSTEM_CLOCK / (2 * A4);
        half_period_lower[10] = SYSTEM_CLOCK / (2 * AS4);
        half_period_lower[11] = SYSTEM_CLOCK / (2 * B4);
        half_period_lower[12] = SYSTEM_CLOCK / (2 * C5);

        half_period_upper[0] = SYSTEM_CLOCK / (2 * C5);
        half_period_upper[1] = SYSTEM_CLOCK / (2 * CS5);
        half_period_upper[2] = SYSTEM_CLOCK / (2 * D5);
        half_period_upper[3] = SYSTEM_CLOCK / (2 * DS5);
        half_period_upper[4] = SYSTEM_CLOCK / (2 * E5);
        half_period_upper[5] = SYSTEM_CLOCK / (2 * F5);
        half_period_upper[6] = SYSTEM_CLOCK / (2 * FS5);
        half_period_upper[7] = SYSTEM_CLOCK / (2 * G5);
        half_period_upper[8] = SYSTEM_CLOCK / (2 * GS5);
        half_period_upper[9] = SYSTEM_CLOCK / (2 * A5);
        half_period_upper[10] = SYSTEM_CLOCK / (2 * AS5);
        half_period_upper[11] = SYSTEM_CLOCK / (2 * B5);
        half_period_upper[12] = SYSTEM_CLOCK / (2 * C6);
    end

    // Individual counters for each note
    reg [31:0] counter [0:12];
    reg [12:0] tone_out;  // Holds the output state for each tone (1 or 0)

    integer i;
    
    initial begin
            for (i = 0; i < 13; i = i + 1) begin
                counter[i] <= 0;
            end
        end

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            // Reset all counters and tone outputs
            for (i = 0; i < 13; i = i + 1) begin
                counter[i] <= 0;
                tone_out[i] <= 0;
            end
        end else begin
            for (i = 0; i < 13; i = i + 1) begin
                if (switches[i]) begin
                    // Use the correct half-period based on the octave switch (switches[13])
                    if (switches[13]) begin
                        // Use upper octave
                        if (counter[i] >= half_period_upper[i]) begin
                            counter[i] <= 0;
                            tone_out[i] <= ~tone_out[i]; // Toggle to create square wave
                        end else begin
                            counter[i] <= counter[i] + 1;
                        end
                    end else begin
                        // Use lower octave
                        if (counter[i] >= half_period_lower[i]) begin
                            counter[i] <= 0;
                            tone_out[i] <= ~tone_out[i]; // Toggle to create square wave
                        end else begin
                            counter[i] <= counter[i] + 1;
                        end
                    end
                end else begin
                    tone_out[i] <= 0; // If switch is off, set output to 0
                end
            end
        end
    end

    // Mix and average all active tones
    reg [15:0] tone_sum;       // Sum of active tones
    reg [3:0] active_tones;    // Count of active tones

    always @(*) begin
        tone_sum = 0;
        active_tones = 0;

        for (i = 0; i < 13; i = i + 1) begin
            if (switches[i]) begin
                tone_sum = tone_sum + tone_out[i];
                active_tones = active_tones + 1;
            end
        end

        // Output averaged tones
        if (active_tones > 0)
            audio_out = tone_sum / active_tones;
        else
            audio_out = 0;
    end
endmodule