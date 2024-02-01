---@class XUiFangKuaiRankDetails : XLuaUi 分数档位弹框
---@field _Control XFangKuaiControl
local XUiFangKuaiRankDetails = XLuaUiManager.Register(XLuaUi, "UiFangKuaiRankDetails")

function XUiFangKuaiRankDetails:OnAwake()
    self:RegisterClickEvent(self.BtnTanchuangCloseBig, self.Close)
end

function XUiFangKuaiRankDetails:OnStart(stageId)
    local stage = self._Control:GetStageConfig(stageId)
    self.TxtTitle.text = XUiHelper.GetText("FangKuaiRankDetailsTitle", stage.Name)
    local configs = self._Control:GetScoreGradeConfig(stageId)
    table.sort(configs, function(a, b)
        return a.Score < b.Score
    end)
    XUiHelper.RefreshCustomizedList(self.PanelContent, self.GridRank, #configs, function(index, grid)
        local config = configs[index]
        local uiObject = {}
        XUiHelper.InitUiClass(uiObject, grid)
        uiObject.TxtDamage.text = config.Score
        uiObject.RankImage:SetRawImage(self._Control:GetStageRankIconByGrade(config.Grade))
        uiObject.ImgBg1.gameObject:SetActiveEx(index % 2 ~= 0)
        uiObject.ImgBg2.gameObject:SetActiveEx(index % 2 == 0)
    end)
end

return XUiFangKuaiRankDetails