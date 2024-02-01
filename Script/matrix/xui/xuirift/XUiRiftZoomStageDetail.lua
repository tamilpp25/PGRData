--大秘境关卡节点详情 跃升
local XUiRiftZoomStageDetail = XLuaUiManager.Register(XLuaUi, "UiRiftZoomStageDetail")
local XUiGridRiftMonsterDetail = require("XUi/XUiRift/Grid/XUiGridRiftMonsterDetail")

function XUiRiftZoomStageDetail:OnAwake()
    self:InitButton()
    self.GridMonsterDic = {}
end

function XUiRiftZoomStageDetail:InitButton()
    XUiHelper.RegisterClickEvent(self, self.BtnCloseMask, self.OnBtnCloseMaskClick)
    XUiHelper.RegisterClickEvent(self, self.BtnFight, self.OnBtnFightClick)
    XUiHelper.RegisterClickEvent(self, self.BtnReward, self.OnBtnRewardClick)
end

function XUiRiftZoomStageDetail:OnStart(layerId, closeCb)
    self.XFightLayer = XDataCenter.RiftManager.GetEntityFightLayerById(layerId)
    self.XStageGroup = self.XFightLayer:GetStage()
    self.CloseCb = closeCb
end

function XUiRiftZoomStageDetail:OnEnable()
    self:RefreshUiShow()
end

function XUiRiftZoomStageDetail:RefreshUiShow()
    -- 关卡信息
    self.TxtStageName.text = self.XStageGroup:GetName()
    self.TxtStageInfo.text = self.XStageGroup:GetDesc()
    self.TxtProgress.text = self.XStageGroup:GetParent():GetJumpCount() .."/" ..self.XStageGroup:GetParent().Config.JumpLayerMaxCount
    -- 敌人情报
    -- 刷新前先隐藏
    for k, grid in pairs(self.GridMonsterDic) do
        grid.GameObject:SetActiveEx(false)
    end
    for k, xMonster in ipairs(self.XStageGroup:GetAllEntityMonsters()) do
        local grid = self.GridMonsterDic[k]
        if not grid then
            local trans = CS.UnityEngine.Object.Instantiate(self.GridMonster, self.GridMonster.parent)
            grid = XUiGridRiftMonsterDetail.New(trans)
            self.GridMonsterDic[k] = grid
        end
        grid:Refresh(xMonster, self.XStageGroup)
        grid.GameObject:SetActiveEx(true)
    end
end

function XUiRiftZoomStageDetail:OnBtnFightClick()
    local doFun = function ()
        local stageId = XDataCenter.RiftManager.GetCurrSelectRiftStageGroup():GetAllEntityStages()[1].StageId -- 单人只有1个stage
        XLuaUiManager.PopThenOpen("UiBattleRoleRoom", stageId
            , XDataCenter.RiftManager.GetSingleTeamData()
            , require("XUi/XUiRift/Grid/XUiRiftBattleRoomProxy"))
    end

    local xChapter = self.XStageGroup:GetParent():GetParent()
    XDataCenter.RiftManager.CheckDayTipAndDoFun(xChapter, doFun)
end

function XUiRiftZoomStageDetail:OnBtnCloseMaskClick()
    self:Close()
end

function XUiRiftZoomStageDetail:OnDestroy()
    self.CloseCb()
end

function XUiRiftZoomStageDetail:OnBtnRewardClick()
    XLuaUiManager.Open("UiRiftPreview", self.XFightLayer)
end

return XUiRiftZoomStageDetail