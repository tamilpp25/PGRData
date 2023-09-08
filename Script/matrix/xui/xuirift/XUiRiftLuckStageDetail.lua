--大秘境关卡节点详情 幸运
local XUiRiftLuckStageDetail = XLuaUiManager.Register(XLuaUi, "UiRiftLuckStageDetail")
local XUiGridRiftMonsterDetail = require("XUi/XUiRift/Grid/XUiGridRiftMonsterDetail")
local XUiRiftPluginGrid = require("XUi/XUiRift/Grid/XUiRiftPluginGrid")

function XUiRiftLuckStageDetail:OnAwake()
    self:InitButton()
    self.GridMonsterDic = {}
    ---@type XUiRiftPluginGrid[]
    self.GridPluginList = {}
end

function XUiRiftLuckStageDetail:InitButton()
    self:BindHelpBtn(self.BtnLuckHelp, "RiftLuckyHelp")
    XUiHelper.RegisterClickEvent(self, self.BtnCloseMask, self.OnBtnCloseMaskClick)
    XUiHelper.RegisterClickEvent(self, self.BtnFight, self.OnBtnFightClick)
end

---@param xStageGroup XRiftStageGroup
function XUiRiftLuckStageDetail:OnStart(xStageGroup, closeCb)
    self.XStageGroup = xStageGroup
    self.CloseCb = closeCb
end

function XUiRiftLuckStageDetail:OnEnable()
    self:RefreshUiShow()
end

function XUiRiftLuckStageDetail:RefreshUiShow()
    -- 敌人情报
    -- 刷新前先隐藏
    for k, grid in pairs(self.GridMonsterDic) do
        grid.GameObject:SetActiveEx(false)
    end
    for k, xMonster in ipairs(XDataCenter.RiftManager:GetLuckMonster()) do
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
    local pluginIds = XDataCenter.RiftManager:GetLuckPlugins()
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
            XLuaUiManager.Open("UiRiftPreview", curFightLayer, true)
        end)
        grid.GameObject:SetActive(true)
    end
    self.GridRiftPlugin.gameObject:SetActiveEx(false)
    -- 幸运值
    local progress = XDataCenter.RiftManager:GetLuckValueProgress()
    local effectValue = XDataCenter.RiftManager:GetCurLuckEffectValue()
    self.ImgBar.fillAmount = progress
    self.TxtNum.text = string.format("%s%%", progress * 100)
    self.BtnFight.gameObject:SetActiveEx(progress >= 1)
    self.PanelBar.gameObject:SetActiveEx(progress < 1)
    self.TxtBuffNum.text = string.format("%s%%", effectValue / 100)
    self.ImgUp.gameObject:SetActiveEx(effectValue > 0)
end

function XUiRiftLuckStageDetail:OnBtnFightClick()
    XDataCenter.RiftManager.RiftStartLuckyNodeRequest(function()
        local stageId = XDataCenter.RiftManager:GetLuckStageId()
        if XTool.IsNumberValid(stageId) then
            XLuaUiManager.PopThenOpen("UiBattleRoleRoom", stageId
            , XDataCenter.RiftManager.GetSingleTeamData(true)
            , require("XUi/XUiRift/Grid/XUiRiftBattleRoomProxy"))
        end
    end)
end

function XUiRiftLuckStageDetail:OnBtnCloseMaskClick()
    self:Close()
end

function XUiRiftLuckStageDetail:OnDestroy()
    if self.CloseCb then
        self.CloseCb()
    end
end

return XUiRiftLuckStageDetail