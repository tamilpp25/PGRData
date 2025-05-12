local XUiGridRiftTemplate = require("XUi/XUiRift/Grid/XUiGridRiftTemplate")
local XRiftAttributeTemplate = require("XModule/XRift/XEntity/XRiftAttributeTemplate")

---@class XUiRiftTemplate:XLuaUi 大秘境队伍加点模板界面
---@field _Control XRiftControl
local XUiRiftTemplate = XLuaUiManager.Register(XLuaUi, "UiRiftTemplate")
local TEMPLATE_CNT = 5

function XUiRiftTemplate:OnAwake()
	---@type XUiGridRiftTemplate[]
	self.GridTemplateList = {}
	self:RegisterEvent()
	self:InitTemplateList()
	self:InitTimes()
end

function XUiRiftTemplate:OnStart(attrTempletaId, changeCb, clearCb, hideBtnClear, hideBtnCover)
	self.CurAttrTemplate = self._Control:GetAttrTemplate(attrTempletaId)
	if not self.CurAttrTemplate then
		self.CurAttrTemplate = self._Control:GetAttrTemplate()
	end

	self.SelectIndex = attrTempletaId
	self.ChangeCb = changeCb
	self.ClearCb = clearCb
	self.BtnClear.gameObject:SetActiveEx(not hideBtnClear)
	self.BtnCover.gameObject:SetActiveEx(not hideBtnCover)

	self:RefreshCurTemplate()
	self:RefreshTemplateList()
end

function XUiRiftTemplate:RegisterEvent()
	self.BtnBgClose.CallBack = handler(self, self.Close)
	self.BtnClose.CallBack = handler(self, self.Close)
	self.BtnUse.CallBack = function()
		self:OnClickBtnUse()
		self:Close()
	end
	self.BtnCover.CallBack = function()
		self:OnClickBtnCover()
	end
	self.BtnClear.CallBack = function()
		self:OnClickBtnClear()
	end
end

function XUiRiftTemplate:OnClickBtnUse()
	if self.ChangeCb then
		self.ChangeCb(self.SelectIndex)
	end
end

function XUiRiftTemplate:OnClickBtnCover()
	if self.SelectIndex == 1 then
		return
	end

	local cloneTemplate = XTool.Clone(self.CurAttrTemplate)
	cloneTemplate.Id = self.SelectIndex
	self._Control:RequestSetAttrSet(cloneTemplate, function()
		self:RefreshGridTemplate(cloneTemplate.Id)
	end)
end

function XUiRiftTemplate:OnClickBtnClear()
	if self.SelectIndex == 1 then
		return
	end

	local xAttrTemplate = XRiftAttributeTemplate.New(self.SelectIndex)
	self._Control:RequestSetAttrSet(xAttrTemplate, function()
		for teamId, xTeam in pairs(self._Control:GetMultiTeamData()) do
			if xTeam:GetAttrTemplateId() == self.SelectIndex then
				self._Control:RiftSetTeamRequest(xTeam, XEnumConst.Rift.DefaultAttrTemplateId, function ()
					if self.ClearCb then
						self.ClearCb(self.SelectIndex)
					end
				end)
			end
		end
		self.SelectIndex = XEnumConst.Rift.DefaultAttrTemplateId
		self:RefreshTemplateList()
	end)
end

function XUiRiftTemplate:OnClickBtnSelectGrid(index)
	self.SelectIndex = index
	for i = 1, TEMPLATE_CNT do
		local xGridRiftTemplate = self.GridTemplateList[i]
		xGridRiftTemplate:SetSelect(i == self.SelectIndex)
	end

	self.BtnUse.gameObject:SetActiveEx(not self.GridTemplateList[self.SelectIndex].IsEmpty)
	self:RefreshBtnList()
end

function XUiRiftTemplate:OnClickBtnCoverGrid(index)
	local cloneTemplate = XTool.Clone(self.CurAttrTemplate)
	cloneTemplate.Id = index
	self._Control:RequestSetAttrSet(cloneTemplate, function()
		self.SelectIndex = index
		self:RefreshTemplateList()
	end)
end

function XUiRiftTemplate:InitTemplateList()
	self.GridTemplateList = {}
	for i = 1, TEMPLATE_CNT do
		local go = self["GridTemplete" .. i]
		local xGridRiftTemplate = XUiGridRiftTemplate.New(go, self, i)
		table.insert(self.GridTemplateList, xGridRiftTemplate)
	end
end

function XUiRiftTemplate:RefreshTemplateList()
	for i = 1, TEMPLATE_CNT do
		self:RefreshGridTemplate(i)
	end

	self:RefreshBtnList()
end

function XUiRiftTemplate:RefreshGridTemplate(index)
	local xGridRiftTemplate = self.GridTemplateList[index]
	local attrTemplate = self._Control:GetAttrTemplate(index)
	xGridRiftTemplate:Refresh(attrTemplate)
	xGridRiftTemplate:SetSelect(index == self.SelectIndex)
end

function XUiRiftTemplate:RefreshBtnList()
	local isSelectDefault = self.SelectIndex == XEnumConst.Rift.DefaultAttrTemplateId
	self.BtnCover:SetDisable(isSelectDefault, not isSelectDefault)
	self.BtnClear:SetDisable(isSelectDefault, not isSelectDefault)
end

function XUiRiftTemplate:RefreshCurTemplate()
	for i = 1, XEnumConst.Rift.AttrCnt do
		self["TxtNowTitle" .. i].text = self._Control:GetTeamAttributeConfig(i).Name
		self["TxtNowAttr" .. i].text = self.CurAttrTemplate:GetAttrLevel(i)
	end
end

function XUiRiftTemplate:InitTimes()
    self:SetAutoCloseInfo(self._Control:GetActivityEndTime(), function(isClose)
        if isClose then
            XLuaUiManager.RunMain()
            XUiManager.TipMsg(XUiHelper.GetText("ActivityAlreadyOver"))
        end
    end)
end
