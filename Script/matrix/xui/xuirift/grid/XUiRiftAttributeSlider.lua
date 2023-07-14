local XUiRiftAttributeSlider = XClass(nil, "UiRiftAttributeSlider")

function XUiRiftAttributeSlider:Ctor(ui, base, index)
	self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Base = base
    self.Index = index
    self.CurLevel = 0

    XTool.InitUiObject(self)
    self:RegisterEvent()
    self:InitTxt()
end

function XUiRiftAttributeSlider:RegisterEvent()
	self.BtnAddSelect.CallBack = function()
		self:OnClickBtnAddSelect()
	end
	self.BtnMinusSelect.CallBack = function()
		self:OnClickBtnMinusSelect()
	end

	self.Slider.onValueChanged:AddListener(function(value)
		local maxValue = self.LimitLevel == 0 and 0 or (self:GetMaxPreviewLevel() / self.LimitLevel)
		if value > maxValue then
			self.Slider.value = maxValue
			value = maxValue
		end

		local curLevel = math.floor(self.LimitLevel * value + 0.5) -- 四舍五入取整
		if curLevel ~= self.CurLevel then
			self.CurLevel = curLevel
			self:RefreshLevel()
			self.Base:OnAttrLevelChange()
		end
	end)
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

function XUiRiftAttributeSlider:InitTxt()
    local config = XRiftConfig.GetCfgByIdKey(XRiftConfig.TableKey.RiftTeamAttribute, self.Index)
	self.TxtTitle.text = config.Name
	self.TxtInformation.text = config.Desc
end

function XUiRiftAttributeSlider:Refresh(curLevel, limitLevel)
	self.CurLevel = curLevel
	self.LimitLevel = limitLevel
	self.LastLevel = curLevel

	self:RefreshSliderBg()
	self:RefreshLevel(true)
end

function XUiRiftAttributeSlider:RefreshSliderBg()
	local fillAmount = self.LastLevel / self.LimitLevel
	self.ImgStripMinBg.fillAmount = fillAmount
	self.ImgStripAddBg.fillAmount = fillAmount
end

function XUiRiftAttributeSlider:RefreshLevel(isAdjustSlider)
	self.TxtLevel.text = tostring(self.CurLevel)
	
	if isAdjustSlider then
		self.Slider.value = self.LimitLevel == 0 and 0 or (self.CurLevel / self.LimitLevel)
	end

	-- 更新slider的颜色
	local isAdd = self.CurLevel >= self.LastLevel
	self.ImgStripMinBg.gameObject:SetActiveEx(not isAdd)
	self.ImgStripAddBg.gameObject:SetActiveEx(isAdd)
	local dragColor = isAdd and "34AFF8" or "0F70BC"
	self.ImgStripDrag.color = XUiHelper.Hexcolor2Color(dragColor)

	self:RefreshButton()
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

return XUiRiftAttributeSlider