XUiPLayerHead = XUiPLayerHead or {}

XUiPLayerHead.InitPortrait = function(HeadPortraitId, HeadFrameId, Object)--为通用头像组件调用这个接口
    if XTool.UObjIsNil(Object) then return end
    
    local uiObject,imgColor = XUiPLayerHead.Create(Object, false)
    if not uiObject then return end
    
    uiObject.gameObject:SetActiveEx(true)
    
    if HeadPortraitId then
        XUiPLayerHead.SetHeadPortrait(HeadPortraitId, uiObject:GetObject("ImgIcon"), uiObject:GetObject("EffectIcon"),imgColor)
    end
    if HeadFrameId then
        XUiPLayerHead.SetHeadFrame(HeadFrameId, uiObject:GetObject("ImgIconKuang"), uiObject:GetObject("EffectKuang"),imgColor)
    end
end

XUiPLayerHead.Hide = function(Object)
    if XTool.UObjIsNil(Object) then return end
    
    local uiObject,_ = XUiPLayerHead.Create(Object, true)
    if not uiObject then return end
    
    uiObject.gameObject:SetActiveEx(false)
end

XUiPLayerHead.Create = function(Object, IsHide)
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

XUiPLayerHead.SetHeadPortrait = function(HeadPortraitId,iconRawImageNode,effectNode,imgColor)
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

XUiPLayerHead.SetHeadFrame = function(HeadFrameId,iconRawImageNode,effectNode,imgColor)
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