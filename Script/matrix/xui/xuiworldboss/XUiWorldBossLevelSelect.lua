local XUiWorldBossLevelSelect = XLuaUiManager.Register(XLuaUi, "UiWorldBossLevelSelect")
local XUiGridLevelSelect = require("XUi/XUiWorldBoss/XUiGridLevelSelect")

function XUiWorldBossLevelSelect:OnStart(stageId, level, cb)
    self.CallBack = cb
    self:SetButtonCallBack()
    self.CurBossLevel = level
    self:InitLevelSelect(stageId)
end

function XUiWorldBossLevelSelect:SetButtonCallBack()
    self.BtnClose.CallBack = function()
        self:OnBtnCloseClick()
    end
end

function XUiWorldBossLevelSelect:OnBtnCloseClick()
    if self.CallBack then
        self.CallBack(self.CurBossLevel)
    end
    self:Close()
end

function XUiWorldBossLevelSelect:InitLevelSelect(stageId)
    if not stageId then
        return
    end
    self.GridLevel.gameObject:SetActiveEx(false)
    local stageList = XDataCenter.WorldBossManager.GetBossStageGroupByIdAndLevel(stageId)
    for _,stage in pairs(stageList) do
        local go = CS.UnityEngine.Object.Instantiate(self.GridLevel, self.LevelContent)
        local selectTtem = XUiGridLevelSelect.New(go, self)
        selectTtem.GameObject:SetActiveEx(true)
        selectTtem:UpdateData(stage)
    end
end