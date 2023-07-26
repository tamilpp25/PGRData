--大秘境关卡节点详情 普通
local XUiRiftNormalStageDetail = XLuaUiManager.Register(XLuaUi, "UiRiftNormalStageDetail")
local XUiGridRiftMonsterDetail = require("XUi/XUiRift/Grid/XUiGridRiftMonsterDetail")

function XUiRiftNormalStageDetail:OnAwake()
    self:InitButton()
    self.GridMonsterDic = {}
end

function XUiRiftNormalStageDetail:InitButton()
    XUiHelper.RegisterClickEvent(self, self.BtnCloseMask, self.OnBtnCloseMaskClick)
    XUiHelper.RegisterClickEvent(self, self.BtnFight, self.OnBtnFightClick)
end

function XUiRiftNormalStageDetail:OnStart(xStageGroup, closeCb)
    self.XStageGroup = xStageGroup
    self.CloseCb = closeCb
end

function XUiRiftNormalStageDetail:OnEnable()
    self:RefreshUiShow()
end

function XUiRiftNormalStageDetail:RefreshUiShow()
    -- 关卡信息
    self.TxtStageName.text = self.XStageGroup:GetName()
    self.TxtStageInfo.text = self.XStageGroup:GetDesc()
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

function XUiRiftNormalStageDetail:OnBtnFightClick()
    local doFun = function ()
        local stageId = XDataCenter.RiftManager.GetCurrSelectRiftStageGroup():GetAllEntityStages()[1].StageId -- 单人只有1个stage
        XLuaUiManager.PopThenOpen("UiBattleRoleRoom", stageId
            , XDataCenter.RiftManager.GetSingleTeamData()
            , require("XUi/XUiRift/Grid/XUiRiftBattleRoomProxy"))
    end
 
    local xChapter = self.XStageGroup:GetParent():GetParent()
    XDataCenter.RiftManager.CheckDayTipAndDoFun(xChapter, doFun)
end

function XUiRiftNormalStageDetail:OnBtnCloseMaskClick()
    self:Close()
end

function XUiRiftNormalStageDetail:OnDestroy()
    self.CloseCb()
end

return XUiRiftNormalStageDetail