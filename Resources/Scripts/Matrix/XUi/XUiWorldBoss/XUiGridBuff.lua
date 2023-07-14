local XUiGridBuff = XClass(nil, "XUiGridBuff")

function XUiGridBuff:Ctor(ui,IsShowCondition)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.AreaId = areaId
    self.IsShowCondition = IsShowCondition
    XTool.InitUiObject(self)

    self:SetButtonCallBack()
end

function XUiGridBuff:SetButtonCallBack()
    self.BtnBuff.CallBack = function()
        self:OnBtnBuffClick()
    end
end

function XUiGridBuff:OnBtnBuffClick()
    XLuaUiManager.Open("UiWorldBossTips",self.Data:GetId(), self.IsShowCondition)
end

function XUiGridBuff:UpdateData(data)
    self.Data = data
    local lockRawImage = XUiHelper.TryGetComponent(self.Transform, "Locked", "RawImage")
    if data then
        if self.BuffIcon then
            self.BuffIcon:SetRawImage(data:GetIcon())
            self.BuffIcon.gameObject:SetActiveEx(not data:GetIsLock() or not self.IsShowCondition)
        end
        if self.Locked then
            self.Locked.gameObject:SetActiveEx(data:GetIsLock())
            if lockRawImage then
                lockRawImage:SetRawImage(data:GetIcon())
            end
        end
        if self.BuffBg then
            self.BuffBg.gameObject:SetActiveEx(data:GetType() == XWorldBossConfigs.BuffType.Buff)
        end
        if self.ImgBuff then
            self.ImgBuff:SetSprite(data:GetIcon())
        end
    end
end

return XUiGridBuff