XFavorabilityManagerCreator = function()
    local XFavorabilityManager = {}
    
    --todo:使用该接口的模块后续替换为接口内的Agency接口
    function XFavorabilityManager.PlayCvByType(characterId, soundType)
        XMVCA.XFavorability:PlayCvByType(characterId, soundType)
    end
    
    --todo:使用该接口的模块后续替换为接口内的Agency接口
    function XFavorabilityManager.StopCv()
        XMVCA.XFavorability:StopCv()
    end
    
    return XFavorabilityManager
end
