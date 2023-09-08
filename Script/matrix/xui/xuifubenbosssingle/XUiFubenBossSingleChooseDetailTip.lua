---@class XUiFubenBossSingleChooseDetailTip : XUiNode
local XUiFubenBossSingleChooseDetailTip = XClass(XUiNode, "XUiFubenBossSingleChooseDetailTip")

function XUiFubenBossSingleChooseDetailTip:OnStart(featuresId)
    self._FeaturesId = featuresId or self._FeaturesId
end

function XUiFubenBossSingleChooseDetailTip:OnEnable()
    self:_Refresh()
end

function XUiFubenBossSingleChooseDetailTip:_Refresh()
    if not self._FeaturesId then
        return
    end
    
    local featureCfg = XFubenConfigs.GetFeaturesById(self._FeaturesId)

    self.TxtName.text = featureCfg.Name
    self.TxtBuff.text = featureCfg.Desc
end

function XUiFubenBossSingleChooseDetailTip:SetFeaturesId(id)
    self._FeaturesId = id
end

return XUiFubenBossSingleChooseDetailTip