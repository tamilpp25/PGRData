---@class XUiFubenBossSingleChooseDetailBuff : XUiNode
---@field RImgIcom UnityEngine.UI.RawImage
---@field TxtName UnityEngine.UI.Text
---@field TxtBuff UnityEngine.UI.Text
---@field ImgfTriangleBg UnityEngine.UI.Image
local XUiFubenBossSingleChooseDetailBuff = XClass(XUiNode, "XUiFubenBossSingleChooseDetailBuff")

--region 生命周期
function XUiFubenBossSingleChooseDetailBuff:OnStart(rootUi)
    self._BuffId = self._BuffId
    self._IsShowDesc = self._IsShowDesc or false
    self._RootUi = rootUi or self.Parent
end

function XUiFubenBossSingleChooseDetailBuff:OnEnable()
    self:_Refresh()
end

--endregion

function XUiFubenBossSingleChooseDetailBuff:SetBuffId(id, isShowDesc)
    self._BuffId = id
    self._IsShowDesc = isShowDesc
end

--region 私有方法
function XUiFubenBossSingleChooseDetailBuff:_Refresh()
    if self._BuffId then
        local buffDetailsCfg = XFubenBabelTowerConfigs.GetBabelBuffConfigs(self._BuffId)

        if self._IsShowDesc then
            self.TxtBuff.text = buffDetailsCfg.Desc
        end

        self.TxtName.text = buffDetailsCfg.Name
        self.RImgIcom:SetRawImage(buffDetailsCfg.BuffBg)
        if buffDetailsCfg.BuffTriangleBg then
            self._RootUi:SetUiSprite(self.ImgfTriangleBg, buffDetailsCfg.BuffTriangleBg)
        end
    end
end

--endregion

return XUiFubenBossSingleChooseDetailBuff
