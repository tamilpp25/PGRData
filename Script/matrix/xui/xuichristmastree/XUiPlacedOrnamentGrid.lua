local XUiPlacedOrnamentGrid = XClass(nil, "XUiPlacedOrnamentGrid")
local MAX_TYPE_NUM = 99 --最大挂点类型序号

function XUiPlacedOrnamentGrid:Ctor(uiRoot)
    self.UiRoot = uiRoot
end

function XUiPlacedOrnamentGrid:Refresh(ui, data, index)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Index = index
    self.Data = data
    self:AutoRegister()
    if data then
        self.RImgIcon:SetRawImage(data.ResPath)
        self.RImgIcon.gameObject:SetActiveEx(true)
        self.RImgIcon.rectTransform.sizeDelta = CS.UnityEngine.Vector2(data.Width * data.PlaceScale, data.Height * data.PlaceScale)
        self.HaveItem = true
    else
        self.RImgIcon.gameObject:SetActiveEx(false)
        self.HaveItem = false
    end
    XTool.InitUiObject(self)
end

function XUiPlacedOrnamentGrid:AutoRegister()
    local type = 1
    if self.Data then
        for k, v in ipairs(self.Data.PartId) do
            if v == self.Index then
                type = self.Data.PosType[k]
                break;
            end
        end
    end

    self.Type = type
    local point = self.Transform:Find("type1")
    local isMatch = false
    for i = 1, MAX_TYPE_NUM do
        local temp = self.Transform:Find("type"..i)
        if temp then
            temp.gameObject:SetActiveEx(i == type)
            if i == type then
                point = temp
                isMatch = true
            end
        else
            break
        end
    end

    if not isMatch then
        XLog.Warning("Can not find correct type in this Point...", "Point:", self.Index, "type:", type)
    end
    
    self.IsPointChange = self.LastPoint ~= point
    if self.IsPointChange then
        self.RImgIcon = point:Find("RawImage"):GetComponent("RawImage")
        self.RedNormal = point:Find("Red").gameObject
        self.RedSelect = point:Find("RedSelect").gameObject
        XUiHelper.RegisterClickEvent(self, self.RImgIcon, self.OnBtnClick)
        self.UiPointer = point:Find("RawImage"):GetComponent("XUiPointer")
        if not self.UiPointer then
            self.RImgIcon.gameObject:AddComponent(typeof(CS.XUiPointer))
        end
    end
    
    self.LastPoint = point
end

function XUiPlacedOrnamentGrid:SetLight(isLight)
    self.IsLight = isLight
    if self.IsSelect and not isLight then
        self:SetSelect(false)
        self.RedNormal:SetActiveEx(false)
        return
    end
    self.RedSelect:SetActiveEx(false)
    self.RedNormal:SetActiveEx(isLight)
end

function XUiPlacedOrnamentGrid:SetSelect(isSelect)
    self.IsSelect = isSelect
    self.IsLight = isSelect or self.IsLight
    self.RedNormal:SetActiveEx(not isSelect)
    self.RedSelect:SetActiveEx(isSelect)
end

function XUiPlacedOrnamentGrid:OnBtnClick()
    XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, XLuaAudioManager.UiBasicsMusic.Main_huge)
    self.UiRoot:SelectItem(self.Index)
end

function XUiPlacedOrnamentGrid:GetInfo()
    -- 第三、四个参数是 isPlaced、isOwn
    return self.Data, self.Index, true, true
end

return XUiPlacedOrnamentGrid