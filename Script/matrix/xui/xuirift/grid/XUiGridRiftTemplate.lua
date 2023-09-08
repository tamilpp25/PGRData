---@class XUiGridRiftTemplate
local XUiGridRiftTemplate = XClass(nil, "UiGridRiftTemplate")
local Normal = CS.UiButtonState.Normal
local Select = CS.UiButtonState.Select

function XUiGridRiftTemplate:Ctor(ui, base, index)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Base = base
    self.Index = index
    self.AttrTemplate = nil -- 属性加点模板

    XTool.InitUiObject(self)
    self:SetButtonCallBack()
end

function XUiGridRiftTemplate:SetButtonCallBack()
    XUiHelper.RegisterClickEvent(self, self.BtnOne, self.OnBtnSelectGrid)
    XUiHelper.RegisterClickEvent(self, self.BtnTwo, self.OnBtnSelectGrid)
    XUiHelper.RegisterClickEvent(self, self.BtnReName, self.OnBtnReName)
end

---@param attrTemplate XRiftAttributeTemplate
function XUiGridRiftTemplate:Refresh(attrTemplate)
    self.AttrTemplate = attrTemplate
    self.IsEmpty = attrTemplate:IsEmpty()
    self.BtnOne.gameObject:SetActiveEx(not self.IsEmpty)
    self.BtnTwo.gameObject:SetActiveEx(self.IsEmpty)

    if not self.IsEmpty then
        local stateNameList = {"Noamal", "Press", "Select"}
        for _, stateName in ipairs(stateNameList) do
            local btnState = self[stateName]
            for i = 1, XRiftConfig.AttrCnt do
                btnState:GetObject("TxtLevel"..i).text = attrTemplate:GetAttrLevel(i)
                btnState:GetObject("TxtTitle"..i).text = XRiftConfig.GetTeamAttributeName(i)
            end
            btnState:GetObject("TxtAllLevel").text = attrTemplate:GetAllLevel()
        end
    end

    self.TxtTittle.text = attrTemplate:GetName()
end

function XUiGridRiftTemplate:OnBtnSelectGrid()
    self.Base:OnClickBtnSelectGrid(self.Index)
end

function XUiGridRiftTemplate:OnBtnReName()
    local maxLen = XDataCenter.RiftManager.GetCurrentConfig().AttrSetNameLength
    XLuaUiManager.Open("UiTeamPrefabReName", function(newName, closeCb)
        XDataCenter.RiftManager.RiftSetAttrSetNameRequest(self.AttrTemplate.Id, newName, function()
            self.TxtTittle.text = self.AttrTemplate:GetName()
            XUiManager.TipError(XUiHelper.GetText("RiftReNameSuccess"))
            XLuaUiManager.Close("UiTeamPrefabReName")
        end)
    end, XUiHelper.GetText("RiftReNameTitle"), maxLen)
end

function XUiGridRiftTemplate:SetSelect(isSelect)
    self.BtnOne:SetButtonState(isSelect and Select or Normal)
    self.BtnTwo:SetButtonState(isSelect and Select or Normal)
end

return XUiGridRiftTemplate