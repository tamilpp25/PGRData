local XUiPanelRiftSysAttribute = require("XUi/XUiRift/Grid/XUiPanelRiftSysAttribute")

---@class XUiRiftAttributeSlider
local XUiRiftAttributeSlider = XClass(nil, "UiRiftAttributeSlider")

function XUiRiftAttributeSlider:Ctor(ui, base, index)
	self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Base = base
    self.Index = index
    self.CurLevel = 0
	self.Pool = {}
	---@type XTableRiftTeamAttribute
	self.Config = XRiftConfig.GetCfgByIdKey(XRiftConfig.TableKey.RiftTeamAttribute, self.Index)
	self.LastValue = 0
	self.isInit = true

    XTool.InitUiObject(self)
    self:RegisterEvent()
    self:InitView()
	XScheduleManager.ScheduleOnce(function()
		self:InitSystemPropNodePos()  -- 异形屏适配 延迟执行
	end, 1)
	---@type XUiPanelRiftSysAttribute
	self.Bubble = XUiPanelRiftSysAttribute.New(self.PanelBuffBubble, self.Base, index)
end

function XUiRiftAttributeSlider:RegisterEvent()
	self.BtnAddSelect.CallBack = function()
		self:OnClickBtnAddSelect()
	end
	self.BtnMinusSelect.CallBack = function()
		self:OnClickBtnMinusSelect()
	end

	self.Slider.onValueChanged:AddListener(function(value)
		local maxValue = self.LimitLevel == 0 and 0 or (self:GetMaxPreviewLevel() / self.Config.LimitMax)
		if value > maxValue then
			self.Slider.value = maxValue
			value = maxValue
		end

		if not self.isInit then -- 初始化时不弹提示
			local maxCanAddValue = self.LimitLevel / self.Config.LimitMax
			if value >= maxCanAddValue and value < 1 then
				XUiManager.TipError(XUiHelper.GetText("RiftAttrLimitMaxCanUnlockTip"))
			elseif value >= 1 then
				XUiManager.TipError(XUiHelper.GetText("RiftAttrLimitMaxTip"))
			end
		end
		self.isInit = false

		local curLevel = math.floor(self.Config.LimitMax * value + 0.5) -- 四舍五入取整
		if curLevel ~= self.CurLevel then
			self.CurLevel = curLevel
			self:RefreshLevel()
			self.Base:OnAttrLevelChange()
		end
	end)

	XUiHelper.RegisterClickEvent(self, self.BtnHelp, self.OnBtnHelpClick)
end

function XUiRiftAttributeSlider:OnBtnHelpClick()
	self.Bubble:Open()
	self:SetPosition()
	if self.Base.OpenBubbleCloseBtn then
		self.Base:OpenBubbleCloseBtn()
	end
end

function XUiRiftAttributeSlider:OnClickBtnAddSelect()
	if self.CurLevel < self.LimitLevel and self.CurLevel < self:GetMaxPreviewLevel() then
		self.CurLevel = self.CurLevel + 1
		self:RefreshLevel(true)
		self.Base:OnAttrLevelChange()
	end
end

function XUiRiftAttributeSlider:OnClickBtnMinusSelect()
	if self.CurLevel > 0 then
		self.CurLevel = self.CurLevel - 1
		self:RefreshLevel(true)
		self.Base:OnAttrLevelChange()
	end
end

function XUiRiftAttributeSlider:InitView()
	local attrLevelMax = XDataCenter.RiftManager.GetAttrLevelMax()
	self.TxtTitle.text = self.Config.Name
	self.TxtInformation.text = self.Config.Desc
	self.ImgStripDragDown.fillAmount = attrLevelMax / self.Config.LimitMax
	self:InitSystemPropNode()
end

function XUiRiftAttributeSlider:Refresh(curLevel, limitLevel)
	self.CurLevel = curLevel
	self.LimitLevel = limitLevel
	self.LastLevel = curLevel

	self:RefreshSliderBg()
	self:RefreshLevel(true)
end

function XUiRiftAttributeSlider:InitSystemPropNode()
	local attrs = XDataCenter.RiftManager:GetSystemAttr(self.Index)
	for _, value in pairs(attrs.Values) do
		if value > 0 then
			local go = XUiHelper.Instantiate(self.GridBuff, self.ImgBg)
			go.gameObject:SetActiveEx(true)
			local uiObject = {}
			XTool.InitUiObjectByUi(uiObject, go)
			self.Pool[value] = uiObject
		end
	end
end

function XUiRiftAttributeSlider:InitSystemPropNodePos()
	for value, uiObject in pairs(self.Pool) do
		local pos = value / self.Config.LimitMax * self.ImgBg.rect.width
		uiObject.Transform.anchoredPosition = CS.UnityEngine.Vector2(pos, 0)
	end
end

function XUiRiftAttributeSlider:RefreshSystemPropNode()
    for value, uiObject in pairs(self.Pool) do
        uiObject.GridBuff1.gameObject:SetActiveEx(value > self.LimitLevel)--未解锁
        uiObject.GridBuff2.gameObject:SetActiveEx(value > self.CurLevel and value <= self.LimitLevel)--未获取
        uiObject.GridBuff3.gameObject:SetActiveEx(value <= self.CurLevel)--已获取
    end
end

function XUiRiftAttributeSlider:RefreshSliderBg()
	local fillAmount = self.LastLevel / self.LimitLevel
	self.ImgStripMinBg.fillAmount = fillAmount

end

function XUiRiftAttributeSlider:RefreshLevel(isAdjustSlider)
	self.TxtLevel.text = tostring(self.CurLevel)

	if isAdjustSlider then
		self.Slider.value = self.LimitLevel == 0 and 0 or (self.CurLevel / self.Config.LimitMax)
	end

	self:RefreshButton()
	self:RefreshSystemPropNode()
end

function XUiRiftAttributeSlider:GetLevel()
	return self.CurLevel
end

-- 预览等级 可购买等级
function XUiRiftAttributeSlider:GetMaxPreviewLevel()
	local previewAllLevel = XDataCenter.RiftManager.GetCanPreviewAttrAllLevel()
	local otherSliderLevel = 0
	for index, slider in ipairs(self.Base.AttrSliderList) do
		if index ~= self.Index then
			otherSliderLevel = otherSliderLevel + slider:GetLevel()
		end
	end

	local maxPreviewLv = previewAllLevel - otherSliderLevel
	if maxPreviewLv > self.LimitLevel then
		maxPreviewLv = self.LimitLevel
	end

	return maxPreviewLv
end

function XUiRiftAttributeSlider:RefreshButton()
	local isAddDisable = self.CurLevel >= self:GetMaxPreviewLevel()
	self.BtnAddSelect:SetDisable(isAddDisable)
	self.BtnMinusSelect:SetDisable(self.CurLevel <= 0)
end

function XUiRiftAttributeSlider:SetPosition()
	local pos = self.Base.Transform:InverseTransformPoint(self.PanelBuffBubble.position)
	local maxPosY = self.PanelBuffBubble.rect.height - self.Base.Transform.rect.height / 2
	local offset = maxPosY - pos.y
	if offset > 0 then
		local curPos = self.PanelBuffBubble.anchoredPosition
		self.PanelBuffBubble.anchoredPosition = CS.UnityEngine.Vector2(curPos.x, curPos.y + offset)
	end
end

return XUiRiftAttributeSlider