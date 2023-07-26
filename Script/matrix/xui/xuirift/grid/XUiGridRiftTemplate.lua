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
    self.BtnOne.CallBack = function()
        self.Base:OnClickBtnSelectGrid(self.Index)
    end

    self.BtnTwo.CallBack = function()
        self.Base:OnClickBtnCoverGrid(self.Index)
    end
end

function XUiGridRiftTemplate:Refresh(attrTemplate)
    self.AttrTemplate = attrTemplate
    local isEmpty = attrTemplate:IsEmpty()
    self.BtnOne.gameObject:SetActiveEx(not isEmpty)
    self.BtnTwo.gameObject:SetActiveEx(isEmpty)

    if not isEmpty then
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

function XUiGridRiftTemplate:SetSelect(isSelect)
    self.BtnOne:SetButtonState(isSelect and Select or Normal)
end

return XUiGridRiftTemplate