import "globals"

local pd <const> = playdate

local synth = pd.sound.synth.new()
local happyTrack = pd.sound.track.new()
happyTrack:setNotes({
    {step=1, velocity=1, note="Db4", length=1},
    {step=2, velocity=1, note="F4", length=1},
    {step=3, velocity=1, note="Ab4", length=1},
})
local happyInst = pd.sound.instrument.new(synth)
happyInst:setVolume(1)
happyTrack:setInstrument(happyInst)
local happySeq = pd.sound.sequence.new()
happySeq:addTrack(happyTrack)
happySeq:setTempo(20)

function playSound()
    happyInst:playNote("Db3", 0.8, 0.1)
end

function playHappySound()
    happySeq:play()
end