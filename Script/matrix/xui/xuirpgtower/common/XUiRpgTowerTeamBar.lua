--Rpg玩法队伍经验面板控件
local XUiRpgTowerTeamBar = XClass(nil, "XUiRpgTowerTeamBar")
local FILL_SPEED = 5
local CSTime = CS.UnityEngine.Time
function XUiRpgTowerTeamBar:Ctor(ui, rootUi)
    self.RootUi = rootUi
    XTool.InitUiObjectByUi(self, ui)
    self.MaxLevel = XDataCenter.RpgTowerManager.GetMaxLevel()
end
--================
--设置等级
--@param number level:等级
--================
function XUiRpgTowerTeamBar:SetLevel(level)
    if level > self.MaxLevel then return end
    self.Level = level
    self.TxtLevel.text = level
    local cfg = XRpgTowerConfig.GetTeamLevelCfgByLevel(level)
    self.NextExp = cfg and cfg.Exp or 0
    self.FillAmountUnit = 1 / self.NextExp
end

function XUiRpgTowerTeamBar:RefreshBar()
    local level = XDataCenter.RpgTowerManager.GetCurrentLevel()
    local exp = XDataCenter.RpgTowerManager.GetCurrentExp()
    self:SetLevel(level)
    self:SetExpText(exp)
end
--================
--检查是否满级
--@return bool:已满级true 未满级false
--================
function XUiRpgTowerTeamBar:CheckIsMaxLevel()
    return self.Level >= self.MaxLevel
end
--================
--设置经验值文本
--@param number current:现在的经验值
--================
function XUiRpgTowerTeamBar:SetExpText(current)
    if not (self.Level == self.MaxLevel) then
        self.TxtExp.text = CS.XTextManager.GetText("CommonSlashStr", current, self.NextExp)
        self.CurrentExp = current
        self.ImgProgressbar.fillAmount = current * self.FillAmountUnit
    else
        self.TxtExp.text = CS.XTextManager.GetText("RpgTowerMaxLevel")
        self.ImgProgressbar.fillAmount = 1
    end
end
--================
--增加经验值
--@param number addExp:增加的经验值
--================
function XUiRpgTowerTeamBar:AddExp(addExp, preExp, preLevel)
    if self.IsMaxLevel then return end
    self:SetLevel(preLevel)
    self:SetExpText(preExp)
    local levelUpCount, remainExp = self:CalculateExpOverFlow(addExp, preExp, preLevel)
    self.PlayLevelUpCount = levelUpCount
    self.DoingLevelUp = self.PlayLevelUpCount > 0
    self.TargetExp = remainExp
    self:StartFillTimer()
end
--================
--计算经验值溢出
--@param number addExp:增加的经验值
--@return number:溢出级数(跳级级数)
--@return number:最后剩余的经验值
--@return bool:是否升至满级
--================
function XUiRpgTowerTeamBar:CalculateExpOverFlow(addExp, preExp, preLevel)
    local levelUpCount = 0
    local tempExp = preExp or 0
    local tempLevel = preLevel or 1
    while(addExp > 0) do
        local levelCfg = XRpgTowerConfig.GetTeamLevelCfgByLevel(tempLevel)
        local deltaLevelUpExp = addExp + tempExp - levelCfg.Exp
        if tempLevel >= self.MaxLevel then
            tempExp = 0
            addExp = 0
        elseif deltaLevelUpExp >= 0 then
            levelUpCount = levelUpCount + 1
            tempExp = 0
            tempLevel = tempLevel + 1
            addExp = deltaLevelUpExp
        else
            tempExp = tempExp + addExp
            addExp = 0
        end
    end
    return levelUpCount, tempExp
end

function XUiRpgTowerTeamBar:StartFillTimer()
    if self.TimerId then return end
    --每帧处理
    self.TimerId = XScheduleManager.ScheduleForever(function()
            if XTool.UObjIsNil(self.Transform) then
                self:StopTimer()
                return
            end
            --若还有剩余的播放升级处理次数，则播放升级处理
            if self.PlayLevelUpCount > 0 or ((not self:CheckIsMaxLevel()) and (self.TargetExp > self.CurrentExp)) then
                local nextFillAmount = self.ImgProgressbar.fillAmount + (self.FillAmountUnit * FILL_SPEED)
                if nextFillAmount >= 1 then
                    nextFillAmount = 1
                    self.ImgProgressbar.fillAmount = 1
                    self:SetExpText(self.NextExp)
                    self:SetLevel(self.Level + 1)
                    self:SetExpText(0)
                    self.PlayLevelUpCount = self.PlayLevelUpCount - 1
                else
                    local nextFillAmount = self.ImgProgressbar.fillAmount + (self.FillAmountUnit * FILL_SPEED)
                    self.ImgProgressbar.fillAmount = nextFillAmount
                    local nextExp = math.floor(self.NextExp * self.ImgProgressbar.fillAmount)
                    if self.PlayLevelUpCount == 0 and (nextExp > self.TargetExp) then
                        nextExp = self.TargetExp
                    end
                    self:SetExpText(nextExp)
                end
            else
                self:StopTimer()
                if self.DoingLevelUp then
                    self.DoingLevelUp = false
                    self:ShowLevelUpTips()
                end
            end
        end, 0)
end

function XUiRpgTowerTeamBar:StopTimer()
    if not self.TimerId then return end
    XScheduleManager.UnSchedule(self.TimerId)
    self.TimerId = nil
end

function XUiRpgTowerTeamBar:ShowLevelUpTips()
    XLuaUiManager.Open("UiRpgTowerLevelUp")
end

function XUiRpgTowerTeamBar:OnDisable()
    self:StopTimer()
end

return XUiRpgTowerTeamBar