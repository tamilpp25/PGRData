--大秘境关卡节点详情 幸运
local XUiRiftLuckStageDetail = XLuaUiManager.Register(XLuaUi, "UiRiftLuckStageDetail")
local XUiGridRiftMonsterDetail = require("XUi/XUiRift/Grid/XUiGridRiftMonsterDetail")
local XUiRiftPluginGrid = require("XUi/XUiRift/Grid/XUiRiftPluginGrid")

function XUiRiftLuckStageDetail:OnAwake()
    self:InitButton()
    self.GridMonsterDic = {}
    self.GridPluginList = {}
end

function XUiRiftLuckStageDetail:InitButton()
    XUiHelper.RegisterClickEvent(self, self.BtnCloseMask, self.OnBtnCloseMaskClick)
    XUiHelper.RegisterClickEvent(self, self.BtnFight, self.OnBtnFightClick)
end

function XUiRiftLuckStageDetail:OnStart(xStageGroup, closeCb)
    self.XStageGroup = xStageGroup
    self.CloseCb = closeCb
end

function XUiRiftLuckStageDetail:OnEnable()
    self:RefreshUiShow()
end

function XUiRiftLuckStageDetail:RefreshUiShow()
    -- 关卡信息(ui写死)
    -- self.TxtStageName.text = self.XStageGroup:GetName()
    -- self.TxtStageInfo.text = self.XStageGroup:GetDesc()
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
    -- 掉落插件
    -- 刷新插件信息
    for i, grid in pairs(self.GridPluginList) do
        grid.GameObject:SetActiveEx(false)
    end
    local curFightLayer = self.XStageGroup:GetParent()
    local pluginIds = curFightLayer.ClientConfig.LuckPluginList
    for i, pluginId in ipairs(pluginIds) do
        local grid =  self.GridPluginList[i]
        if not grid then
            local ui = CS.UnityEngine.Object.Instantiate(self.GridRiftPlugin, self.GridRiftPlugin.parent)
            grid = XUiRiftPluginGrid.New(ui)
            self.GridPluginList[i] = grid
        end
        local xPlugin = XDataCenter.RiftManager.GetPlugin(pluginId)
        grid:Refresh(xPlugin)
        grid:Init(function ()
            XLuaUiManager.Open("UiRiftPluginShopTips", {PluginId = pluginId})
        end)
        grid.GameObject:SetActive(true)
    end
    self.GridRiftPlugin.gameObject:SetActiveEx(false)
end

function XUiRiftLuckStageDetail:OnBtnFightClick()
    local stageId = XDataCenter.RiftManager.GetCurrSelectRiftStageGroup():GetAllEntityStages()[1].StageId -- 单人只有1个stage
    XLuaUiManager.PopThenOpen("UiBattleRoleRoom", stageId
        , XDataCenter.RiftManager.GetSingleTeamData()
        , require("XUi/XUiRift/Grid/XUiRiftBattleRoomProxy"))
end

function XUiRiftLuckStageDetail:OnBtnCloseMaskClick()
    self:Close()
end

function XUiRiftLuckStageDetail:OnDestroy()
    self.CloseCb()
end

return XUiRiftLuckStageDetail