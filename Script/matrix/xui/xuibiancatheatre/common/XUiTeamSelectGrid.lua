local XUiTeamSelectGrid = XClass(nil, "XUiTeamSelectGrid")

local MAX_IMG_DI_COUNT = 5

--肉鸽2.0 分队选择的格子
function XUiTeamSelectGrid:Ctor(ui, clickCb)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.ClickCb = clickCb
    XUiHelper.InitUiClass(self, ui)

    self.TapImage = self.Tap:GetComponent("Image")
    self.ImgQuality.gameObject:SetActiveEx(false)
    self:InitBtn()
    self:InitTap()
end

function XUiTeamSelectGrid:InitBtn()
    self.Btn.gameObject:SetActiveEx(false)
end

function XUiTeamSelectGrid:InitTap()
    if self.Tap then self.Tap.gameObject:SetActiveEx(false) end
    if self.Tap1 then self.Tap1.gameObject:SetActiveEx(false) end
    if self.Tap2 then self.Tap2.gameObject:SetActiveEx(false) end
    if self.Tap3 then self.Tap3.gameObject:SetActiveEx(false) end
    if self.Tap4 then self.Tap4.gameObject:SetActiveEx(false) end
end

--biancaTheatreTeamId：BiancaTheatreTeam配置表的Id
function XUiTeamSelectGrid:Refresh(biancaTheatreTeamId, isSelect)
    self.BiancaTheatreTeamId = biancaTheatreTeamId

    self.TxtDes.text = XBiancaTheatreConfigs.GetTeamName(biancaTheatreTeamId)
    self.TxtProgress.text = XBiancaTheatreConfigs.GetTeamDesc(biancaTheatreTeamId)
    self.RImgIcon:SetRawImage(XBiancaTheatreConfigs.GetTeamIcon(biancaTheatreTeamId))

    --是否已解锁
    local conditionId = XBiancaTheatreConfigs.GetTeamConditionId(biancaTheatreTeamId)
    local isUnlock, desc = true, ""
    if XTool.IsNumberValid(conditionId) then
        isUnlock, desc = XDataCenter.BiancaTheatreManager.CheckTeamUnlock(biancaTheatreTeamId), XConditionManager.GetConditionDescById(conditionId)
    end
    if not isUnlock then
        local curProgress, allProgress = XDataCenter.BiancaTheatreManager.GetConditionProcess(conditionId)
        self.TxtUnlockDesc2.text = string.format(XBiancaTheatreConfigs.GetClientConfig("TeamUnLockConditionProgress"), curProgress, allProgress)
    end
    self.IsUnlock = isUnlock
    self.TxtUnlockDesc.text = desc
    self.Disable.gameObject:SetActiveEx(not isUnlock)
    --是否选中
    self:SetSelectActive(isSelect)
    --通关奖章
    local endingIdList = XBiancaTheatreConfigs.GetEndingIdList()
    for i = 1, MAX_IMG_DI_COUNT do
        if not XTool.UObjIsNil(self["ImgDi" .. i]) then
            self["ImgDi" .. i].gameObject:SetActiveEx(false)
        end
    end
    for i, endingId in ipairs(endingIdList) do
        local endingIsActive = XDataCenter.BiancaTheatreManager.GetTeamEndingIsActive(biancaTheatreTeamId, endingId)
        local recordIndex = XBiancaTheatreConfigs.GetEndingRecordIndex(endingId)
        if recordIndex and not XTool.UObjIsNil(self["ImgDi" .. recordIndex]) then
            self["ImgDi" .. recordIndex].gameObject:SetActiveEx(endingIsActive)
        end
    end
    --分队类型标签
    local teamType = XBiancaTheatreConfigs.GetTeamType(biancaTheatreTeamId)
    local teamTypeColor = XBiancaTheatreConfigs.GetTeamTypeColor(teamType)
    if teamTypeColor then
        self.TextTap.text = XBiancaTheatreConfigs.GetTeamTypeName(teamType)
        if self.TapImage then
            self.TapImage.color = XUiHelper.Hexcolor2Color(teamTypeColor)
        end
    end
    self.Tap.gameObject:SetActiveEx(teamTypeColor and true or false)
end

function XUiTeamSelectGrid:OnBtnClick()
    if self.ClickCb then
        self.ClickCb(self)
    end
end

function XUiTeamSelectGrid:SetSelectActive(isActive)
    self.Select.gameObject:SetActiveEx(isActive)
end

function XUiTeamSelectGrid:GetTeamId()
    return self.BiancaTheatreTeamId
end

function XUiTeamSelectGrid:GetIsUnlock()
    return self.IsUnlock
end

return XUiTeamSelectGrid