

local XUiCourseAssetPanel = XClass(nil, "XUiCourseAssetPanel")
local MAX_ITEM_MEMBER = 3

function XUiCourseAssetPanel:Ctor(ui)
    XTool.InitUiObjectByUi(self, ui)
    self.ItemId = XCourseConfig.GetPointItemId()
    self.CourseData = XDataCenter.CourseManager.GetCourseData()
    self:InitUi()
end 

function XUiCourseAssetPanel:InitUi()
    for i = 2, MAX_ITEM_MEMBER do
        self["PanelSpecialTool"..i].gameObject:SetActiveEx(false)
    end

    self.BtnClick1.CallBack = function()
        self:OnBtnClickClick()
    end

    local data = XGoodsCommonManager.GetGoodsShowParamsByTemplateId(self.ItemId)
    self.RImgSpecialTool1:SetRawImage(data.Icon)
end

function XUiCourseAssetPanel:Refresh()
    self.TxtSpecialTool1.text = self.CourseData:GetTotalPointByStageType(XCourseConfig.SystemType.Lesson)
end

function XUiCourseAssetPanel:OnBtnClickClick()
    XLuaUiManager.Open("UiTip", XDataCenter.CourseManager.GetTipShowItemData(), self.HideSkipBtn)
end

return XUiCourseAssetPanel