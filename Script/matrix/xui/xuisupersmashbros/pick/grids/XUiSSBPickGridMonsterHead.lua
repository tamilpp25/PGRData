--================
--怪物头像控件
--================
local XUiSSBPickGridMonsterHead = XClass(nil, "XUiSSBPickGridMonsterHead")

function XUiSSBPickGridMonsterHead:Ctor()

end

function XUiSSBPickGridMonsterHead:Init(ui, list)
    self.List = list
    XTool.InitUiObjectByUi(self, ui)
    --点击事件写在列表事件
    XUiHelper.RegisterClickEvent(self, self.BtnClick, function() self:OnClick() end)
end

function XUiSSBPickGridMonsterHead:Refresh(monsterData, teamData)
    if not monsterData then return end
    if monsterData and monsterData.RandomGrid then --若这是随机格，则设置为随机选取
        self:SetRandom()
        return
    end
    self.MonsterGroup = monsterData
    self.IsRandom = false
    if self.PanelAbility then
        self.PanelAbility.gameObject:SetActiveEx(true)
    end
    if self.TxtAbility then
        self.TxtAbility.text = self.MonsterGroup:GetAbility()
    end
    if self.RImgIcon then
        self.RImgIcon:SetRawImage(self.MonsterGroup:GetIcon())
    end
    if self.PanelFirst then
        self.PanelFirst.gameObject:SetActiveEx(not self.MonsterGroup:CheckIsClear())
    end
    if self.PanelCheck then
        local roleId = self.MonsterGroup:GetId()
        local isCheck = false
        local pos = 0
        for position, teamRoleId in pairs(teamData) do
            if teamRoleId == roleId then
                isCheck = true
                pos = position
                break
            end
        end
        self.PanelCheck.gameObject:SetActiveEx(isCheck)
        if isCheck and self.TxtCheck then
            self.TxtCheck.text = XUiHelper.GetText("SSBCharaHeadCheck", pos)
        end
    end
    if self.PanelDisable then
        local stageId = self.List.Panel.RootUi.Scene and self.List.Panel.RootUi.Scene.Id
        local checkId = self.MonsterGroup:GetLimitStageId()
        local result = checkId > 0 and (checkId ~= stageId)
        self.PanelDisable.gameObject:SetActiveEx(result)
        self.IsDisable = result
    end
    if self.PanelLock then
        self:SetLock()
    end
end

function XUiSSBPickGridMonsterHead:SetLock()
    local startTime = XDataCenter.SuperSmashBrosManager.GetActivityStartTime()
    local now = XTime.GetServerNowTimestamp()
    local delta = now - startTime
    local result = self.MonsterGroup:GetOpenTime() - delta
    self.IsLock = result > 0 
    self.PanelLock.gameObject:SetActiveEx(self.IsLock)
    if self.IsLock then
        self.TxtLock.text = XUiHelper.GetText("SSBMonsterCanActive", XUiHelper.GetTime(result, XUiHelper.TimeFormatType.ACTIVITY))
    end
end

function XUiSSBPickGridMonsterHead:SetRandom()
    self.IsRandom = true
    if self.PanelAbility then
        self.PanelAbility.gameObject:SetActiveEx(false)
    end
    if self.PanelFirst then
        self.PanelFirst.gameObject:SetActiveEx(false)
    end
    if self.RImgIcon then
        self.RImgIcon:SetRawImage(CS.XGame.ClientConfig:GetString("SmashBrosCharaHeadRandom"))
    end
    if self.PanelCheck then
        self.PanelCheck.gameObject:SetActiveEx(false)
    end
    if self.PanelLock then
        self.PanelLock.gameObject:SetActiveEx(false)
    end
    if self.PanelDisable then
        self.PanelDisable.gameObject:SetActiveEx(false)
    end
    self.IsLock = false
    self.IsDisable = false
end

function XUiSSBPickGridMonsterHead:GetMonsterId()
    if self.IsRandom then return XSuperSmashBrosConfig.PosState.Random end
    return self.MonsterGroup:GetId()
end

function XUiSSBPickGridMonsterHead:OnClick()
    if self.IsLock then
        XUiManager.TipText("SSBMonsterLock")
        return
    elseif self.IsDisable then
        XUiManager.TipText("SSBMonsterDisable")
        return
    end
    self.List:OnGridSelect(self)
end

return XUiSSBPickGridMonsterHead