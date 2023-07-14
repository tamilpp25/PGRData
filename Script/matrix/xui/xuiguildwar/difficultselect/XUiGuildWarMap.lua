---@class XUiGuildWarMap
local XUiGuildWarMap = XLuaUiManager.Register(XLuaUi, "UiGuildWarMap")

function XUiGuildWarMap:OnStart(difficultyId)
    self.DifficultyId = difficultyId
    self:InitPanels()
end

function XUiGuildWarMap:InitPanels()
    local cfg = XGuildWarConfig.GetCfgByIdKey(
            XGuildWarConfig.TableKey.Difficulty,
            self.DifficultyId
        )
    self:InitTopControl()
    self:InitPanelSpecialTool()
    self:InitMap(cfg.MapPath)
    self:InitNodesList()
    self:InitRewardsList(cfg.PassRewardId)
end

function XUiGuildWarMap:InitTopControl()
    self.TopController = XUiHelper.NewPanelTopControl(self, self.TopControlWhite)
end

function XUiGuildWarMap:InitPanelSpecialTool()
    --不显示资源栏
    self.PanelSpecialTool.gameObject:SetActiveEx(false)
    --[[
    local itemIds = {
            XDataCenter.ItemManager.ItemId.FreeGem,
            XDataCenter.ItemManager.ItemId.ActionPoint,
            XDataCenter.ItemManager.ItemId.Coin
        }
    XUiHelper.NewPanelActivityAsset(itemIds, self.PanelSpecialTool)]]
end

function XUiGuildWarMap:InitMap(map)
    self.RImgMap:SetRawImage(map)
end

function XUiGuildWarMap:InitNodesList()
    local nodesCfg = XGuildWarConfig.GetAllConfigs(
            XGuildWarConfig.TableKey.Node
        )
    local nodes = {}
    local nodesName = XGuildWarConfig.GetClientConfigValues("StageTypeName", "string")
    local nodesIcon = XGuildWarConfig.GetClientConfigValues("StageTypeIcon", "string")
    for _, node in pairs(nodesCfg or {}) do
        if node.DifficultyId == self.DifficultyId then
            if not nodes[node.Type] then
                nodes[node.Type] = { Icon = nodesIcon[node.Type], Num = 0, Name = nodesName[node.Type] }
            end
            nodes[node.Type].Num = nodes[node.Type].Num + 1
        end
    end
    self.GirdNode.gameObject:SetActiveEx(false)
    local nodeDetailItem = require("XUi/XUiGuildWar/DifficultSelect/XUiGuildWarMapNodeDetailItem")
    for nodeType, node in pairs(nodes) do
        local ui = XUiHelper.Instantiate(self.GirdNode ,self.PanelNodeList)
        local grid = nodeDetailItem.New(ui)
        grid:Refresh(node)
        grid.GameObject:SetActiveEx(true)
    end
end

function XUiGuildWarMap:InitRewardsList(rewardId)
    self.GridReward.gameObject:SetActiveEx(false)
    local rewards = XRewardManager.GetRewardList(rewardId)
    if rewards then
        for i, item in pairs(rewards) do
            local ui = XUiHelper.Instantiate(self.GridReward ,self.PanelRewardList)
            local grid = XUiGridCommon.New(self, ui)
            grid:Refresh(item)
            grid.GameObject:SetActiveEx(true)
        end
    end
end