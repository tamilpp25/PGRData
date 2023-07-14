local handler = handler

local XUiGridStrongholdBuff = XClass(nil, "XUiGridStrongholdBuff")

function XUiGridStrongholdBuff:Ctor(ui, hideClick, skipCb, openSkillDetailsCb, closeSkillDetailsCb, isClickBtnUseDialog)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform

    XTool.InitUiObject(self)

    self.SkipCb = skipCb
    self.OpenSkillDetailsCb = openSkillDetailsCb    --开启技能说明界面回调
    self.CloseSkillDetailsCb = closeSkillDetailsCb  --关闭技能说明界面回调
    self.IsClickBtnUseDialog = isClickBtnUseDialog  --开启技能说明界面时是否使用Dialog的界面类型

    self:SetDisable(false)

    if self.BtnClick then 
        self.BtnClick.CallBack = handler(self, self.OnClickBtnClick)
    end

    if hideClick then
        self.BtnClick.gameObject:SetActiveEx(false)
    end

    if self.Effect then
        self.Effect.gameObject:SetActiveEx(false)
    end
end

--isBossBuff为true时条件取反，即满足条件后设置为关闭
function XUiGridStrongholdBuff:Refresh(buffId, isBossBuff)
    self.BuffId = buffId

    if self.RImgIconBuff1 then
        local icon = XStrongholdConfigs.GetBuffIcon(buffId)
        self.RImgIconBuff1:SetRawImage(icon)
    end

    if self.RImgIconBuff2 then
        local icon = XStrongholdConfigs.GetBuffIcon(buffId)
        self.RImgIconBuff2:SetRawImage(icon)
    end

    local isBuffActive = XDataCenter.StrongholdManager.CheckBuffActive(buffId, isBossBuff)
    self:SetDisable(not isBuffActive)

    if self.Effect then
        self.Effect.gameObject:SetActiveEx(false)

        if self.OldIsActive ~= nil then
            if self.OldIsActive ~= isBuffActive then
                XScheduleManager.ScheduleOnce(function()
                    if XTool.UObjIsNil(self.Effect) then return end
                    self.Effect.gameObject:SetActiveEx(true)
                end, 0.5 * XScheduleManager.SECOND)
            end
        end
        self.OldIsActive = isBuffActive
    end
end

function XUiGridStrongholdBuff:SetDisable(value)
    if self.BuffDisable then
        self.BuffDisable.gameObject:SetActiveEx(value)
    end

    if self.BuffNormal then
        self.BuffNormal.gameObject:SetActiveEx(not value)
    end
end

function XUiGridStrongholdBuff:OnClickBtnClick()
    if self.OpenSkillDetailsCb then
        self.OpenSkillDetailsCb()
    end
    local uiName = self.IsClickBtnUseDialog and "UiStrongholdSkillDetailsDialog" or "UiStrongholdSkillDetails"
    XLuaUiManager.Open(uiName, self.BuffId, self.SkipCb, self.CloseSkillDetailsCb)
end

return XUiGridStrongholdBuff