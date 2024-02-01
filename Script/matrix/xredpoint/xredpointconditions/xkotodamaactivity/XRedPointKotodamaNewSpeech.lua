local XRedPointKotodamaNewSpeech = {}

function XRedPointKotodamaNewSpeech.Check()
    local allSentences=XMVCA.XKotodamaActivity:GetAllUnLockCollectSentenceIds()
    for i, id in pairs(allSentences) do
        if XMVCA.XKotodamaActivity:CheckSpeechIsNew(id) then
            return true
        end
    end
    return false
end

return XRedPointKotodamaNewSpeech