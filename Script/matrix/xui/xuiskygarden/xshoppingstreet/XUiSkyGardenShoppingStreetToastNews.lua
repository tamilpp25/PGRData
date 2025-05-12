---@class XUiSkyGardenShoppingStreetToastNews : XLuaUi
---@field TxtTitle UnityEngine.UI.Text
---@field TxtDetail UnityEngine.UI.Text
---@field BtnClose XUiComponent.XUiButton
---@field ImgNewsBg UnityEngine.UI.Image
---@field ImgMessageBg UnityEngine.UI.Image
local XUiSkyGardenShoppingStreetToastNews = XMVCA.XBigWorldUI:Register(nil, "UiSkyGardenShoppingStreetToastNews")

--region 生命周期
function XUiSkyGardenShoppingStreetToastNews:OnAwake()
    self:_RegisterButtonClicks()
end

function XUiSkyGardenShoppingStreetToastNews:OnStart(params)
    self._CloseCallback = params.CloseCallback
    
    local currentTurn = self._Control:GetRunRound()
    local newses = self._Control:GetStageNews()
    local grapevines = self._Control:GetStageGrapevines()

    local newsData = newses[currentTurn]
    if newsData then
        local newsCfg = self._Control:GetNewsConfigById(newsData.NewsId)
        self.TxtTitle.text = newsCfg.Name
        self.TxtDetail.text = newsCfg.Desc
    else
        self.PanelNew.gameObject:SetActive(false)
    end

    local grapevinesData = grapevines[currentTurn]
    if grapevinesData then
        self.TxtGrapevineDetail.text = self._Control:ParseGrapevine(grapevinesData)
    else
        self.PanelMessageBg.gameObject:SetActive(false)
        self.PanelMessage.gameObject:SetActive(false)
    end
end
--endregion

--region 按钮事件
function XUiSkyGardenShoppingStreetToastNews:OnBtnCloseClick()
    self:Close()
    if self._CloseCallback then
        self._CloseCallback()
        self._CloseCallback = nil
    end
end

--endregion

--region 私有方法
function XUiSkyGardenShoppingStreetToastNews:_RegisterButtonClicks()
    --在此处注册按钮事件
    self.BtnClose.CallBack = function() self:OnBtnCloseClick() end
end
--endregion

return XUiSkyGardenShoppingStreetToastNews
