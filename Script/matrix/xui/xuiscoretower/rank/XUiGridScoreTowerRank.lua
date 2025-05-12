---@class XUiGridScoreTowerRank : XUiNode
---@field private _Control XScoreTowerControl
local XUiGridScoreTowerRank = XClass(XUiNode, "XUiGridScoreTowerRank")

function XUiGridScoreTowerRank:OnStart()
    if self.BtnDetail then
        XUiHelper.RegisterClickEvent(self, self.BtnDetail, self.OnBtnDetailClick, nil, true)
    end
    self.GridTeam.gameObject:SetActiveEx(false)
    ---@type UiObject[]
    self.GridTeamList = {}
    ---@type XScoreTowerRankPlayer
    self.PlayerInfo = nil
    self.RankNum = 0
end

---@param playerInfo XScoreTowerRankPlayer 玩家信息
function XUiGridScoreTowerRank:SetPlayerInfo(playerInfo)
    self.PlayerInfo = playerInfo or nil
end

---@param rankNum number 排名
function XUiGridScoreTowerRank:SetRankNum(rankNum)
    self.RankNum = rankNum or 0
end

-- 计算比率 向上取整
function XUiGridScoreTowerRank:CalculateRate()
    if self.RankNum <= 0 then
        return "0"
    end
    if self.RankNum <= 100 then
        return tostring(self.RankNum)
    end
    local totalCount = self._Control:GetQueryRankTotalCount()
    if totalCount <= 0 then
        return "0"
    end
    local rate = math.ceil(self.RankNum / totalCount * 100)
    return string.format("%d%%", math.min(rate, 100))
end

-- 刷新排名
---@param isShowRate boolean 是否显示比率
function XUiGridScoreTowerRank:RefreshRank(isShowRate)
    self.ImgRankSpecial.gameObject:SetActiveEx(false)
    self.TxtRankNormal.gameObject:SetActiveEx(true)
    self.TxtRankNormal.text = isShowRate and self:CalculateRate() or tostring(self.RankNum)
end

-- 刷新玩家信息
function XUiGridScoreTowerRank:RefreshPlayerInfo()
    if not self.PlayerInfo then
        self.TxtPlayerName.text = XPlayer.Name
        XUiPlayerHead.InitPortrait(XPlayer.CurrHeadPortraitId, XPlayer.CurrHeadFrameId, self.Head)
        return
    end

    self.TxtPlayerName.text = self.PlayerInfo:GetName()
    XUiPlayerHead.InitPortrait(self.PlayerInfo:GetHeadPortraitId(), self.PlayerInfo:GetHeadFrameId(), self.Head)
end

-- 刷新boss头像
function XUiGridScoreTowerRank:RefreshBossHead()
    if not self.PlayerInfo then
        self.PanelBoss.gameObject:SetActiveEx(false)
        return
    end

    self.PanelBoss.gameObject:SetActiveEx(true)
    self.TxtRankScore.text = self.PlayerInfo:GetScore()
    local stageCfgId = self.PlayerInfo:GetScoreTowerStageCfgId()
    local bossHeadIcon = self._Control:GetStageBossHeadIcon(stageCfgId)
    if not string.IsNilOrEmpty(bossHeadIcon) then
        self.RImgBossHead:SetRawImage(bossHeadIcon)
    end
end

-- 刷新队伍信息
function XUiGridScoreTowerRank:RefreshTeamInfo()
    if not self.PlayerInfo then
        self.PlayerTeam.gameObject:SetActiveEx(false)
        return
    end

    self.PlayerTeam.gameObject:SetActiveEx(true)
    local characterIds = self.PlayerInfo:GetCharacterIds()
    for i = 1, 3 do
        local grid = self.GridTeamList[i]
        local entityId = characterIds[i]
        if XTool.IsNumberValid(entityId) then
            if not grid then
                grid = XUiHelper.Instantiate(self.GridTeam, self.PlayerTeam)
                self.GridTeamList[i] = grid
            end
            grid.gameObject:SetActiveEx(true)
            local characterId = XEntityHelper.GetCharacterIdByEntityId(entityId)
            grid:GetObject("RImgTeam"):SetRawImage(XMVCA.XCharacter:GetCharSmallHeadIcon(characterId))
        elseif grid then
            grid.gameObject:SetActiveEx(false)
        end
    end
end

function XUiGridScoreTowerRank:OnBtnDetailClick()
    if not self.PlayerInfo then
        return
    end
    XDataCenter.PersonalInfoManager.ReqShowInfoPanel(self.PlayerInfo:GetId())
end

-- 播放动画
function XUiGridScoreTowerRank:PlayEnableAnim()
    self:PlayAnimation("GridRankEnable", function()
        self:SetCanvasGroupAlpha(1)
    end)
end

-- 设置透明度
function XUiGridScoreTowerRank:SetCanvasGroupAlpha(alpha)
    if self.CanvasGroup then
        self.CanvasGroup.alpha = alpha
    end
end

return XUiGridScoreTowerRank
