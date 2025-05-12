---@class XUiArenaNewGridPlayer : XUiNode
---@field ImgBgUp UnityEngine.UI.Image
---@field ImgBgHold UnityEngine.UI.Image
---@field ImgBgDown UnityEngine.UI.Image
---@field ImgIconUp UnityEngine.UI.Image
---@field TxtRank UnityEngine.UI.Text
---@field ImgMedal UnityEngine.UI.Image
---@field TxtName UnityEngine.UI.Text
---@field TxtScoreNum UnityEngine.UI.Text
---@field ImgChangeUpper UnityEngine.UI.Image
---@field TxtUpper UnityEngine.UI.Text
---@field ImgChangeLower UnityEngine.UI.Image
---@field TxtLower UnityEngine.UI.Text
---@field ImgChange UnityEngine.UI.Image
---@field HeadObject UnityEngine.RectTransform
---@field BtnPlayer XUiComponent.XUiButton
---@field _Control XArenaControl
local XUiArenaNewGridPlayer = XClass(XUiNode, "XUiArenaNewGridPlayer")

-- region 生命周期

---@param groupPlayerData XArenaGroupPlayerData
function XUiArenaNewGridPlayer:OnStart(regionType, groupPlayerData, rank)
    self._RegionType = regionType
    self._PlayerData = groupPlayerData
    self._Rank = rank

    self:_RegisterButtonClicks()
end

function XUiArenaNewGridPlayer:OnEnable()
    self:_Refresh()
    self:_RefreshUpperTag()
end

-- endregion

---@param groupPlayerData XArenaGroupPlayerData
function XUiArenaNewGridPlayer:Refresh(regionType, groupPlayerData, rank)
    self._RegionType = regionType
    self._PlayerData = groupPlayerData
    self._Rank = rank
end

-- region 按钮事件

function XUiArenaNewGridPlayer:OnBtnPlayerClick()
    if self._PlayerData then
        local playerId = self._PlayerData:GetId()

        if playerId ~= XPlayer.Id then
            XDataCenter.PersonalInfoManager.ReqShowInfoPanel(playerId)
        end
    end
end

-- endregion

-- region 私有方法
function XUiArenaNewGridPlayer:_RegisterButtonClicks()
    -- 在此处注册按钮事件
    XUiHelper.RegisterClickEvent(self, self.BtnPlayer, self.OnBtnPlayerClick, true)
end

function XUiArenaNewGridPlayer:_Refresh()
    local medalId = self._PlayerData:GetCurrentMedalId()

    if not XTool.IsNumberValid(medalId) then
        self.ImgMedal.gameObject:SetActiveEx(false)
    else
        local medalIcon = self._Control:GetMedalIconByMedalId(medalId)

        if medalIcon then
            self.ImgMedal.gameObject:SetActiveEx(true)
            self.ImgMedal:SetSprite(medalIcon)

            XDataCenter.MedalManager.LoadMedalEffect(self, self.ImgMedal, medalId)
        else
            self.ImgMedal.gameObject:SetActiveEx(false)
        end
    end

    self.ImgBgUp.gameObject:SetActiveEx(self._RegionType == XEnumConst.Arena.RegionType.Up)
    self.ImgBgHold.gameObject:SetActiveEx(self._RegionType == XEnumConst.Arena.RegionType.Keep)
    self.ImgBgDown.gameObject:SetActiveEx(self._RegionType == XEnumConst.Arena.RegionType.Down)
    self.TxtName.text = XDataCenter.SocialManager.GetPlayerRemark(self._PlayerData:GetId(), self._PlayerData:GetName())
    self.TxtRank.text = XUiHelper.GetText("ArenaRank", self._Rank) 
    self.TxtScoreNum.text = self._PlayerData:GetPoint()
    XUiPlayerHead.InitPortraitWithoutStandIcon(self._PlayerData:GetCurrentHeadPortraitId(),
        self._PlayerData:GetCurrentHeadFrameId(), self.HeadObject)

    self:_RefreshUpIcon()
end

function XUiArenaNewGridPlayer:_RefreshUpIcon()
    if self._RegionType == XEnumConst.Arena.RegionType.Down then
        self.ImgIconUp.gameObject:SetActiveEx(false)
        return
    end
    if self.Parent:GetArenaLevel() ~= self._Control:GetArenaHeroLv() then
        self.ImgIconUp.gameObject:SetActiveEx(false)
        return
    end

    local danUpRank = self._Control:GetChallengeDanUpRankByChallengeId(self.Parent:GetChallengeId())

    if danUpRank < self._Rank then
        self.ImgIconUp.gameObject:SetActiveEx(false)
        return
    end

    local score = self._PlayerData:GetContributeScore() or 0

    if score < self._Control:GetMaxContributeScore() then
        self.ImgIconUp.gameObject:SetActiveEx(false)
        return
    end

    self.ImgIconUp.gameObject:SetActiveEx(true)
end

function XUiArenaNewGridPlayer:_RefreshUpperTag()
    if self._Control:IsInActivityFightStatus() then
        self.ImgChangeUpper.gameObject:SetActiveEx(false)
        self.ImgChangeLower.gameObject:SetActiveEx(false)
        self.ImgChange.gameObject:SetActiveEx(false)
    else
        local localRank = self._Control:GetLocalPlayerRankByPlayerId(self._PlayerData:GetId())

        if XTool.IsNumberValid(localRank) then
            local rankingsFluctuate = localRank - self._Rank

            if rankingsFluctuate > 0 then
                self.ImgChangeUpper.gameObject:SetActiveEx(true)
                self.ImgChangeLower.gameObject:SetActiveEx(false)
                self.ImgChange.gameObject:SetActiveEx(false)
                self.TxtUpper.text = rankingsFluctuate
            elseif rankingsFluctuate < 0 then
                self.ImgChangeUpper.gameObject:SetActiveEx(false)
                self.ImgChangeLower.gameObject:SetActiveEx(true)
                self.ImgChange.gameObject:SetActiveEx(false)
                self.TxtLower.text = math.abs(rankingsFluctuate)
            else
                self.ImgChangeUpper.gameObject:SetActiveEx(false)
                self.ImgChangeLower.gameObject:SetActiveEx(false)
                self.ImgChange.gameObject:SetActiveEx(true)
            end
        else
            self.ImgChangeUpper.gameObject:SetActiveEx(false)
            self.ImgChangeLower.gameObject:SetActiveEx(false)
            self.ImgChange.gameObject:SetActiveEx(false)
        end
    end
end

-- endregion

return XUiArenaNewGridPlayer
