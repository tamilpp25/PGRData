local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
---@class XUiGuildWarMap:XLuaUi
local XUiGuildWarMap = XLuaUiManager.Register(XLuaUi, "UiGuildWarMap")

function XUiGuildWarMap:OnStart(difficultyId)
    self.GridBuff.gameObject:SetActiveEx(false)
    self.GridBuffs = {}
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
    local passRewardId = XGuildWarConfig.GetDifficultyPassRewardId(self.DifficultyId)
    self:InitRewardsList(passRewardId)
    self:InitTerm2()
    self:RefreshBuff(cfg.FightEventIds)
    self.TxtTitleName.text = cfg.Name
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
    --不显示在节点预览的节点类型
    local excludeNodeType = {
        [XGuildWarConfig.NodeType.Home] = true,
        [XGuildWarConfig.NodeType.PandaChild] = true,
        [XGuildWarConfig.NodeType.TwinsChild] = true,
        [XGuildWarConfig.NodeType.Term3SecretRoot] = true,
        [XGuildWarConfig.NodeType.Term3SecretChild] = true,
        [XGuildWarConfig.NodeType.Term4BossChild] = true,
    }
    for _, node in pairs(nodesCfg or {}) do
        if node.DifficultyId == self.DifficultyId and not excludeNodeType[node.Type] then
            if not XTool.IsNumberValid(node.RootId) then
                if not nodes[node.Type] then
                    nodes[node.Type] = { Icon = nodesIcon[node.Type], Num = 0, Name = nodesName[node.Type] }
                end
                nodes[node.Type].Num = nodes[node.Type].Num + 1
            end
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

--region 二期
function XUiGuildWarMap:InitTerm2()
    XUiHelper.RegisterClickEvent(self, self.BtnSelect, self.Select)
    self:ShowRecommendedActivation()
    self:UpdateBtnSelect()
end

-- 推荐活跃度
function XUiGuildWarMap:ShowRecommendedActivation()
    if XDataCenter.GuildWarManager.IsLastRound() then
        self.TxtActiveTips.text = XUiHelper.GetText("GuildWarRemindLastRound")
        self.TxtActive.gameObject:SetActiveEx(false)
        return
    end

    local activation = XGuildWarConfig.GetDifficultyRecommendActivation(self.DifficultyId)
    if activation > 0 then
        if XDataCenter.GuildWarManager.IsActivationNotRecommend(self.DifficultyId) then
            self.TxtActive.text = XUiHelper.GetText("GuildWarRecommendActiveNotEnough", activation)
        else
            self.TxtActive.text = XUiHelper.GetText("GuildWarRecommendActive", activation)
        end
    else
        self.TxtActive.text = ""
    end
end

-- 选择按钮
function XUiGuildWarMap:UpdateBtnSelect()
    local button = self.BtnSelect

    -- 没有下一轮
    if XDataCenter.GuildWarManager.IsLastRound() then
        button:SetButtonState(CS.UiButtonState.Disable)
        button:SetNameByGroup(0, XUiHelper.GetText("GuildWarSelectDifficulty"))
        return
    end

    -- 已选择
    if XDataCenter.GuildWarManager.GetNextDifficultyId() == self.DifficultyId then
        button:SetButtonState(CS.UiButtonState.Disable)
        button:SetNameByGroup(0, XUiHelper.GetText("GuildBossStyleSelected"))
        return
    end

    -- 解锁
    if XDataCenter.GuildWarManager.CheckDifficultyIsUnlock(self.DifficultyId) then
        button:SetButtonState(CS.UiButtonState.Normal)
        button:SetNameByGroup(0, XUiHelper.GetText("GuildWarSelectDifficulty"))
        return
    end

    -- 未解锁
    button:SetButtonState(CS.UiButtonState.Disable)
    button:SetNameByGroup(0, XUiHelper.GetText("RpgTowerTalentLock"))
end

function XUiGuildWarMap:Select()
    if self.BtnSelect.ButtonState == CS.UiButtonState.Disable then
        return
    end
    XDataCenter.GuildWarManager.SelectDifficulty(self.DifficultyId, function()
        self:UpdateBtnSelect()
    end)
end

function XUiGuildWarMap:UpdateDetails()
    local fightEventArray = XGuildWarConfig.GetDifficultyFightEvents(self.DifficultyId)
    local imageFightEventArray = { self.ImageBuff }
    for i = 1, #fightEventArray - 1 do
        local gameObject = CS.UnityEngine.Object.Instantiate(self.ImageBuff.gameObject)
        imageFightEventArray[#imageFightEventArray + 1] = XUiHelper.TryGetComponent(gameObject.transform, "", "RawImage")
    end
    for i = 1, #imageFightEventArray do
        local imageBuff = imageFightEventArray[i]
        local buffId = fightEventArray[i]
        if not buffId then
            imageBuff.gameObject:SetActiveEx(false)
        else
            imageBuff:SetRawImage(XGuildWarConfig.GetFightEventIcon(buffId))
        end
    end
end

function XUiGuildWarMap:RefreshBuff(fightEventIds)
    for index, fightEventId in pairs(fightEventIds or {}) do
        local buff = self:GetBuff(index)
        buff:Show()
        buff:Refresh(fightEventId, fightEventIds)
    end
    for index = #fightEventIds + 1, #self.GridBuffs do
        local buff = self:GetBuff(index)
        buff:Hide()
    end
end

function XUiGuildWarMap:GetBuff(index)
    local buff = self.GridBuffs[index]
    if buff then
        return buff
    end
    local newGo = XUiHelper.Instantiate(self.GridBuff, self.GridBuff.transform.parent)
    if newGo then
        local buffGridScript = require("XUi/XUiGuildWar/DifficultSelect/XUiGWSelectBuffGrid")
        local newBuff = buffGridScript.New(newGo)
        self.GridBuffs[index] = newBuff
    end
    return self.GridBuffs[index]
end

--endregion
