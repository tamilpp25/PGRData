---@class XUiPanelRogueSimLvUp : XUiNode
---@field private _Control XRogueSimControl
local XUiPanelRogueSimLvUp = XClass(XUiNode, "XUiPanelRogueSimLvUp")

function XUiPanelRogueSimLvUp:OnStart()
    XUiHelper.RegisterClickEvent(self, self.BtnLvUp, self.OnBtnLvUpClick)
    self.TxtFullLv.gameObject:SetActiveEx(true)
end

function XUiPanelRogueSimLvUp:Refresh(isAnim)
    local expId = XEnumConst.RogueSim.ResourceId.Exp
    -- 等级
    local curLevel = self._Control:GetCurMainLevel()
    self.TxtLv.text = curLevel
    -- 资源名
    self.TxtTitle.text = self._Control.ResourceSubControl:GetResourceName(expId)
    -- 资源图标
    self.ImgExp:SetRawImage(self._Control.ResourceSubControl:GetResourceIcon(expId))
    -- 是否是最大等级
    local isMaxLevel = self._Control:CheckIsMaxLevel(curLevel)
    self.PanelConsume.gameObject:SetActiveEx(not isMaxLevel)
    self.TxtNumMax.gameObject:SetActiveEx(not isMaxLevel)
    -- 按钮文本
    self.BtnLvUp:SetNameByGroup(0, self._Control:GetClientConfig("MainLevelBtnLvUpText", isMaxLevel and 2 or 1))
    if isMaxLevel then
        self.TxtNum.text = self._Control:GetClientConfig("MainMaxLevelDesc")
        self.ImgBar.fillAmount = 1
        -- 已满级
        self.TxtFullLv.text = self._Control:GetClientConfig("MainLevelUpExpTips", 2)
    else
        local curExp, upExp = self._Control:GetCurExpAndLevelUpExp(curLevel)
        if curExp > 0 and isAnim then
            self:PlayExpAddAnimation(curExp, upExp)
        else
            self:RefreshExp(curExp, upExp)
        end
        -- 金币
        local isEnough = self._Control:CheckLevelUpGoldIsEnough(curLevel)
        self.PanelConsumeOn.gameObject:SetActiveEx(isEnough)
        self.PanelConsumeOff.gameObject:SetActiveEx(not isEnough)
        local panel = isEnough and self.PanelConsumeOn or self.PanelConsumeOff
        local goldId = XEnumConst.RogueSim.ResourceId.Gold
        -- 原价
        local goldCount = self._Control:GetCurLevelUpGoldCount(curLevel)
        -- 折扣后的价格
        local discountGoldCount = self._Control:GetCurLevelUpGoldCountWithDiscount(curLevel)
        panel:GetObject("Icon"):SetRawImage(self._Control.ResourceSubControl:GetResourceIcon(goldId))
        panel:GetObject("TxtConsumeNumber").text = discountGoldCount
        self.TxtDiscount.gameObject:SetActiveEx(discountGoldCount ~= goldCount)
        self.TxtDiscount.text = goldCount
    end
    -- 状态
    self:RefreshBtnStatus()
end

function XUiPanelRogueSimLvUp:RefreshExp(curExp, upExp)
    self.TxtNum.text = string.format("%d/", curExp)
    self.TxtNumMax.text = upExp
    -- 进度条
    self.ImgBar.fillAmount = XTool.IsNumberValid(upExp) and curExp / upExp or 1
    -- 可升级
    self.TxtFullLv.text = curExp >= upExp and self._Control:GetClientConfig("MainLevelUpExpTips", 1) or ""
end

function XUiPanelRogueSimLvUp:RefreshBtnStatus()
    local isCanLevelUp = self._Control:CheckMainLevelCanLevelUp()
    self.BtnLvUp:SetDisable(not isCanLevelUp)
end

function XUiPanelRogueSimLvUp:OnBtnLvUpClick()
    local isCanLevelUp, desc = self._Control:CheckMainLevelCanLevelUp()
    if not isCanLevelUp then
        XUiManager.TipMsg(desc)
        return
    end
    -- 升级
    self._Control:RogueSimMainLevelUpRequest()
end

-- 播放经验增加动画
function XUiPanelRogueSimLvUp:PlayExpAddAnimation(curExp, upExp)
    local onRefresh = function(f)
        if XTool.UObjIsNil(self.GameObject) then
            return
        end
        self:RefreshExp(XMath.ToMinInt(f * curExp), upExp)
    end
    local onFinish = function()
        if XTool.UObjIsNil(self.GameObject) then
            return
        end
        XLuaUiManager.SetMask(false)
    end
    -- 时长
    local time = tonumber(self._Control:GetClientConfig("MainLevelUpExpAnimTime", 1))
    XLuaUiManager.SetMask(true)
    XUiHelper.Tween(time, onRefresh, onFinish)
end

return XUiPanelRogueSimLvUp
