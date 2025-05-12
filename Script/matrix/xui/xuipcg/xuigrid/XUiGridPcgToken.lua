---@class XUiGridPcgToken : XUiNode
---@field private _Control XPcgControl
local XUiGridPcgToken = XClass(XUiNode, "XUiGridPcgToken")

function XUiGridPcgToken:OnStart()
    self.TxtDetail.requestImage = XMVCA.XPcg.RichTextImageCallBack
end

function XUiGridPcgToken:OnEnable()
    
end

function XUiGridPcgToken:OnDisable()
    
end

function XUiGridPcgToken:OnDestroy()

end

-- 设置数据
function XUiGridPcgToken:SetData(cfgId)
    self.CfgId = cfgId
    self:Refresh()
end

function XUiGridPcgToken:Refresh()
    local tokenCfg = self._Control:GetConfigToken(self.CfgId)
    self.RImgIcon:SetRawImage(tokenCfg.Icon)
    self.TxtTitle.text = tokenCfg.Name
    self.TxtDetail.text = XUiHelper.ReplaceTextNewLine(tokenCfg.Desc)
end

return XUiGridPcgToken
