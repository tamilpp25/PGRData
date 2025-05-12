---@class XUiTheatre4RecruitGrid : XUiNode
---@field _Control XTheatre4Control
local XUiTheatre4RecruitGrid = XClass(XUiNode, "XUiTheatre4RecruitGrid")

function XUiTheatre4RecruitGrid:OnStart()
    ---@type XTheatre4SetControlMemberData
    self._Data = nil
    self._Control:RegisterClickEvent(self, self.BtnRecruit, self.OnClickHire)
    self._Control:RegisterClickEvent(self, self.BtnRankUp, self.OnClickHire)
end

---@param data XTheatre4SetControlMemberData
function XUiTheatre4RecruitGrid:Update(data)
    self._Data = data
    self.TxtName.text = data.Name
    --self.BtnRecruit
    --self.TxtName
    --self.OverRecruit
    --self.BtnElementDetail
    --self.RImgCharElement1
    --self.RImgCharElement2
    --self.RImgCharElement3
    --self.BtnGeneralSkill1
    --self.BtnGeneralSkill2
    --self.PanelColour
    self:SetResource(self.TxtLvNumBlue, data.ResourceList[3])
    self:SetResource(self.TxtLvNumYellow, data.ResourceList[2])
    self:SetResource(self.TxtLvNumRed, data.ResourceList[1])

    if data.IsShowStarButton then
        if self.BtnRankUp then
            self.BtnRankUp.gameObject:SetActiveEx(true)
            self.BtnRecruit.gameObject:SetActiveEx(false)
        else
            self.BtnRecruit.gameObject:SetActiveEx(true)
        end
    else
        if self.BtnRankUp then
            self.BtnRankUp.gameObject:SetActiveEx(false)
        end
        self.BtnRecruit.gameObject:SetActiveEx(true)
    end

    self.TxtLevel.text = data.Star
end

function XUiTheatre4RecruitGrid:SetResource(label, value)
    if value and value > 0 then
        label.transform.parent.gameObject:SetActiveEx(true)
        label.text = "x" .. value
    else
        label.transform.parent.gameObject:SetActiveEx(false)
    end
end

function XUiTheatre4RecruitGrid:OnClickHire()
    self._Control.SetControl:RequestHire(self._Data)
end

return XUiTheatre4RecruitGrid