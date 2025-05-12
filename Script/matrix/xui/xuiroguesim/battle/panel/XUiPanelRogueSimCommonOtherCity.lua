---@class XUiPanelRogueSimCommonOtherCity : XUiNode
---@field private _Control XRogueSimControl
local XUiPanelRogueSimCommonOtherCity = XClass(XUiNode, "XUiPanelRogueSimCommonOtherCity")

function XUiPanelRogueSimCommonOtherCity:OnStart()
    self.Star.gameObject:SetActiveEx(false)
    ---@type UiObject[]
    self.GridStarList = {}
end

---@param id number 城邦自增Id
function XUiPanelRogueSimCommonOtherCity:Refresh(id)
    self.Id = id
    self.CurLevel = self._Control.MapSubControl:GetCityLevelById(id)
    self:RefreshCityInfo()
    self:RefreshLevel()
    self:PlayAnimationWithMask("PanelOtherCityEnable")
end

-- 刷新等级
function XUiPanelRogueSimCommonOtherCity:RefreshLevel()
    local maxLevel = self._Control.MapSubControl:GetCityMaxLevelById(self.Id)
    for i = 1, maxLevel do
        local grid = self.GridStarList[i]
        if not grid then
            grid = XUiHelper.Instantiate(self.Star, self.PanelLv)
            self.GridStarList[i] = grid
        end
        grid.gameObject:SetActiveEx(true)
        local isOn = self.CurLevel >= i
        grid:GetObject("On").gameObject:SetActiveEx(isOn)
        grid:GetObject("Off").gameObject:SetActiveEx(not isOn)
    end
    for i = maxLevel + 1, #self.GridStarList do
        self.GridStarList[i].gameObject:SetActiveEx(false)
    end
end

-- 刷新城邦信息
function XUiPanelRogueSimCommonOtherCity:RefreshCityInfo()
    -- 标题
    local isUpgrade = self.CurLevel > 1
    self.TxtUpgrade.gameObject:SetActive(isUpgrade)
    self.TxtUnlock.gameObject:SetActive(not isUpgrade)
    local cityLevelConfigId = self._Control.MapSubControl:GetCityLevelConfigIdById(self.Id, self.CurLevel)
    -- 图标
    local icon = self._Control.MapSubControl:GetCityLevelIcon(cityLevelConfigId)
    if icon then
        self.RImgCity:SetRawImage(icon)
    end
    -- 标志
    local flagIcon = self._Control.MapSubControl:GetCityLevelFlagIcon(cityLevelConfigId)
    if flagIcon then
        self.ImgTag:SetSprite(flagIcon)
    end
    -- 名称
    self.TxtName.text = self._Control.MapSubControl:GetCityLevelName(cityLevelConfigId)
    -- 解锁buff
    self.TxtBuffDetail.text = self._Control.MapSubControl:GetCityLevelBuffDesc(cityLevelConfigId)
    -- 经验
    local rewardExp = self._Control.MapSubControl:GetCityLevelUnlockExpReward(cityLevelConfigId)
    self.PanelExp.gameObject:SetActiveEx(rewardExp > 0)
    if rewardExp > 0 then
        self.TxtExpNum.text = string.format("+%d", rewardExp)
        local expIcon = self._Control.ResourceSubControl:GetResourceIcon(XEnumConst.RogueSim.ResourceId.Exp)
        if expIcon then
            self.ImgExpIcon:SetSprite(expIcon)
        end
    end
end

return XUiPanelRogueSimCommonOtherCity
