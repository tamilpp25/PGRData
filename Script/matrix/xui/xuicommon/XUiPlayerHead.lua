local XUiPlayerHead = {}

XUiPlayerHead.InitPortrait = function(HeadPortraitId, HeadFrameId, Object)--为通用头像组件调用这个接口
    if XTool.UObjIsNil(Object) then return end
    
    local uiObject,imgColor = XUiPlayerHead.Create(Object, false)
    if not uiObject then return end
    
    uiObject.gameObject:SetActiveEx(true)
    
    if HeadPortraitId then
        XUiPlayerHead.SetHeadPortrait(HeadPortraitId, uiObject:GetObject("ImgIcon"), uiObject:GetObject("EffectIcon"),imgColor)
    end
    if HeadFrameId then
        XUiPlayerHead.SetHeadFrame(HeadFrameId, uiObject:GetObject("ImgIconKuang"), uiObject:GetObject("EffectKuang"),imgColor)
    end
end

XUiPlayerHead.Hide = function(Object)
    if XTool.UObjIsNil(Object) then return end
    
    local uiObject,_ = XUiPlayerHead.Create(Object, true)
    if not uiObject then return end
    
    uiObject.gameObject:SetActiveEx(false)
end

XUiPlayerHead.Create = function(Object, IsHide)
    local uiObject = Object.transform:GetComponent("UiObject")
    if not uiObject then return end
    
    local headObject = Object.gameObject:FindTransform("HeadObject")
    
    local standIcon = uiObject:GetObject("StandIcon")
    standIcon.gameObject:SetActiveEx(false)
    
    if XTool.UObjIsNil(headObject) and not IsHide then
        headObject = CS.UnityEngine.Object.Instantiate(uiObject:GetObject("HeadObject"))
        headObject.gameObject.name = "HeadObject"
        headObject.transform:SetParent(Object.transform, false)
    end
    
    return ((not XTool.UObjIsNil(headObject)) and headObject.transform:GetComponent("UiObject") or nil) , standIcon.color
end

XUiPlayerHead.SetHeadPortrait = function(HeadPortraitId, iconRawImageNode, effectNode, imgColor)
   local headPortraitInfo = XPlayerManager.GetHeadPortraitInfoById(HeadPortraitId)
    if headPortraitInfo ~= nil then
        if iconRawImageNode then
            if headPortraitInfo.ImgSrc then
                iconRawImageNode:SetRawImage(headPortraitInfo.ImgSrc)
                iconRawImageNode.color = imgColor
                iconRawImageNode.gameObject:SetActiveEx(true)
            else
                iconRawImageNode.gameObject:SetActiveEx(false)
            end 
        end

        if effectNode then
            if headPortraitInfo.Effect then
                effectNode.gameObject:LoadPrefab(headPortraitInfo.Effect)
                effectNode.gameObject:SetActiveEx(true)
            else
                effectNode.gameObject:SetActiveEx(false)
            end  
        end
    else
        if iconRawImageNode then
            iconRawImageNode.gameObject:SetActiveEx(false)
        end
        
        if effectNode then
            effectNode.gameObject:SetActiveEx(false) 
        end
    end
end

XUiPlayerHead.SetHeadFrame = function(HeadFrameId, iconRawImageNode, effectNode, imgColor)
    local headPortraitInfo = XPlayerManager.GetHeadPortraitInfoById(HeadFrameId)
    if headPortraitInfo ~= nil then
        if iconRawImageNode then
            if headPortraitInfo.ImgSrc then
                iconRawImageNode.color = imgColor
                iconRawImageNode:SetRawImage(headPortraitInfo.ImgSrc)
                iconRawImageNode.gameObject:SetActiveEx(true)
            else
                iconRawImageNode.gameObject:SetActiveEx(false)
            end
        end

        if effectNode then
            if headPortraitInfo.Effect then
                effectNode.gameObject:LoadPrefab(headPortraitInfo.Effect)
                effectNode.gameObject:SetActiveEx(true)
            else
                effectNode.gameObject:SetActiveEx(false)
            end
        end
    else
        if iconRawImageNode then
            iconRawImageNode.gameObject:SetActiveEx(false)
        end

        if effectNode then
            effectNode.gameObject:SetActiveEx(false)
        end
    end
end

XUiPlayerHead.InitPortraitWithoutStandIcon = function(headPortraitId, headFrameId, headObject)
    if XTool.UObjIsNil(headObject) then
        return
    end

    local uiObject = headObject.transform:GetComponent("UiObject") or nil

    if not uiObject then
        headObject.gameObject:SetActiveEx(false)
        return
    end

    headObject.gameObject:SetActiveEx(true)
    if headPortraitId then
        local headIcon = uiObject:GetObject("ImgIcon")

        XUiPlayerHead.SetHeadPortrait(headPortraitId, headIcon, uiObject:GetObject("EffectIcon"), headIcon.color)
    end
    if headFrameId then
        local frameIcon = uiObject:GetObject("ImgIconKuang")

        XUiPlayerHead.SetHeadFrame(headFrameId, frameIcon, uiObject:GetObject("EffectKuang"), frameIcon.color)
    end
end

return XUiPlayerHead