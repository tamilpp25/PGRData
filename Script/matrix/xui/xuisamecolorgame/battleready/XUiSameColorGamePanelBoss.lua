local XUiSameColorGameGridBossSkill = require("XUi/XUiSameColorGame/BattleReady/XUiSameColorGameGridBossSkill")

---@class XUiSameColorGamePanelBoss:XUiNode
---@field _Control XSameColorControl
local XUiSameColorGamePanelBoss = XClass(XUiNode, "XUiSameColorGamePanelBoss")

function XUiSameColorGamePanelBoss:Ctor(ui, rootUi)
    ---@type XUiSameColorGameBoss
    self.RootUi = rootUi
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self.QieHuan = XUiHelper.TryGetComponent(self.Transform, "Animation/QieHuan")
    ---@type XSCBoss
    self.Boss = nil
    self:AddBtnListener()
end

--region Ui - Refresh
---@param boss XSCBoss
function XUiSameColorGamePanelBoss:SetData(boss)
    self.Boss = boss
    
    if self.TxtName then
        self.TxtName.text = boss:GetName()
    end
    if not string.IsNilOrEmpty(boss:GetNameEnIcon()) and self.RImgName then
        self.RImgName:SetRawImage(boss:GetNameEnIcon())
    end
    
    self:RefreshBossInfo()
    self:RefreshElement()
    self:RefreshFlaw()
end
--endregion

--region Ui - BossInfo
function XUiSameColorGamePanelBoss:RefreshBossInfo()
    --local maxScore = self.Boss:GetMaxScore()
    --local showGradeInfo = self.Boss:GetIsOpen() and maxScore > 0
    --self.TxtMaxScore.text = XUiHelper.GetText("SCBossMaxScoreText", maxScore)
    --self.TxtMaxScore.gameObject:SetActiveEx(showGradeInfo)
    --self.RImgGradeIcon.gameObject:SetActiveEx(showGradeInfo)
    --self.RImgGradeIcon:SetRawImage(self.Boss:GetMaxGradeIcon())

    self.TxtTimesTitle.text = self.Boss:IsRoundType() and XUiHelper.GetText("SameColorRoundTitle")
            or self.Boss:IsTimeType() and XUiHelper.GetText("SameColorTimeTitle")
    self.TxtTimes.text = self.Boss:IsRoundType() and self.Boss:GetMaxRound()
            or self.Boss:IsTimeType() and self.Boss:GetMaxTime()
end
--endregion

--region Ui - Element
function XUiSameColorGamePanelBoss:RefreshElement()
    if not self.RImgElement then
        return
    end
    self.RImgElement:SetRawImage(self._Control:GetCfgAttributeTypeIcon(self.Boss:GetAttributeType()))
    self.TxtElementDescribe.text =  self._Control:GetCfgAttributeTypeBossDesc(self.Boss:GetAttributeType())
end
--endregion

--region Ui - 破绽
function XUiSameColorGamePanelBoss:RefreshFlaw()
    self.TxtRule.text = XUiHelper.GetText("SameColorGameWeakRule")
    local skills = XSameColorGameConfigs.GetBossSkills(self.Boss:GetId())
    table.sort(skills, function(a, b)
        return a.Id < b.Id
    end)
    XUiHelper.RefreshCustomizedList(self.GridBossSkill.parent, self.GridBossSkill, #skills, function(index, grid)
        local uiObject = {}
        local ball = XSameColorGameConfigs.GetBallConfig(skills[index].WeakBallIds[1])
        XUiHelper.InitUiClass(uiObject, grid)
        uiObject.ImgIcon:SetRawImage(skills[index].Icon)
        uiObject.TxtName.text = skills[index].Name
        uiObject.TxtDesc.text = skills[index].Desc
        uiObject.TxtHp.text = XUiHelper.GetText("SameColorGameWeakHp", ball.WeakHitTimes)
    end)
end
--endregion

--region Ui - BtnListener
function XUiSameColorGamePanelBoss:AddBtnListener()
    local func = function()
        self.RootUi:UpdateChildPanel(XEnumConst.SAME_COLOR_GAME.UI_BOSS_CHILD_PANEL_TYPE.MAIN)
    end
    self.BtnRole.CallBack = func
    XUiHelper.RegisterClickEvent(self, self.BtnClose, func)
end
--endregion

return XUiSameColorGamePanelBoss