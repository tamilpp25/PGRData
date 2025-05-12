---@class XUiSkyGardenShoppingStreetAsset : XUiNode
---@field TxtGold UnityEngine.UI.Text
---@field TxtFavorability UnityEngine.UI.Text
---@field TxtEnvironmental UnityEngine.UI.Text
---@field TxtPassenger UnityEngine.UI.Text
---@field TxtNumGridPassenger UnityEngine.UI.Text
---@field TxtNumGridEnvironmental UnityEngine.UI.Text
---@field TxtNumGridFavorability UnityEngine.UI.Text
---@field TxtNumGridGold UnityEngine.UI.Text
---@field GridBuff UnityEngine.RectTransform
---@field BubbleBuffDetail UnityEngine.RectTransform
---@field PanelBuff UnityEngine.RectTransform
---@field GridBuffBubbleBuffDetail UnityEngine.RectTransform
---@field TxtDetail UnityEngine.UI.Text
local XUiSkyGardenShoppingStreetAsset = XClass(XUiNode, "XUiSkyGardenShoppingStreetAsset")
local XUiSkyGardenShoppingStreetBuffGrid = require("XUi/XUiSkyGarden/XShoppingStreet/Grid/XUiSkyGardenShoppingStreetBuffGrid")
local XUiSkyGardenShoppingStreetBuffDetailGrid = require("XUi/XUiSkyGarden/XShoppingStreet/Grid/XUiSkyGardenShoppingStreetBuffDetailGrid")
local XUiSkyGardenShoppingStreetAssetTag = require("XUi/XUiSkyGarden/XShoppingStreet/Grid/XUiSkyGardenShoppingStreetAssetTag")

--region 生命周期
function XUiSkyGardenShoppingStreetAsset:OnStart(...)
    self:_RegisterButtonClicks()

    if self.ScrollView then
        self.DetailRt = self.ScrollView.gameObject:GetComponent(typeof(CS.UnityEngine.RectTransform))
        self.DefaultRtSizeY = self.DetailRt.sizeDelta.y
    end

    self._stageResType = XMVCA.XSkyGardenShoppingStreet.StageResType
    self._ResIndex = {
        self._stageResType.InitGold,
        self._stageResType.InitFriendly,
        self._stageResType.InitCustomerNum,
        self._stageResType.InitEnvironment,
    }
    self._ComponentDic = {
        [self._stageResType.InitGold] = {
            self.TxtGold,
            self.TxtNumGridGold,
            self.ImgGoldAsset,
            self.TxtGoldChange,
        },
        [self._stageResType.InitFriendly] = {
            self.TxtFavorability,
            self.TxtNumGridFavorability,
            self.ImgFavorabilityAsset,
            self.TxtFavorabilityChange,
        },
        [self._stageResType.InitCustomerNum] = {
            self.TxtPassenger,
            self.TxtNumGridPassenger,
            self.ImgPassengerAsset,
            self.TxtPassengerChange,
        },
        [self._stageResType.InitEnvironment] = {
            self.TxtEnvironmental,
            self.TxtNumGridEnvironmental,
            self.ImgEnvironmentalAsset,
            self.TxtEnvironmentalChange,
        },
    }

    local resCfgs = self._Control:GetStageResConfigs()
    for _, key in ipairs(self._ResIndex) do
        local value = self._ComponentDic[key]
        local cfg = resCfgs[key]
        value[1].text = cfg.Desc
        -- value[2].color = XUiHelper.Hexcolor2Color(cfg.Color)
        value[3]:SetSprite(cfg.Icon)
        value[4].gameObject:SetActive(false)
    end

    self.BubbleAssetDetail.gameObject:SetActive(false)
    if self.PanelBuffDetail then self.PanelBuffDetail.gameObject:SetActive(false) end
end

function XUiSkyGardenShoppingStreetAsset:OnEnable()
    self:_RefreshRes()
    self:_RefreshBuffs()
end

function XUiSkyGardenShoppingStreetAsset:OnGetLuaEvents()
    return {
        XMVCA.XBigWorldService.DlcEventId.EVENT_BUSINESS_STREET_RES_REFRESH,
        XMVCA.XBigWorldService.DlcEventId.EVENT_BUSINESS_STREET_BUFF_REFRESH,
    }
end

function XUiSkyGardenShoppingStreetAsset:OnNotify(event, resType, add)
    if event == XMVCA.XBigWorldService.DlcEventId.EVENT_BUSINESS_STREET_RES_REFRESH then
        self:_RefreshRes(resType, add)
    elseif event == XMVCA.XBigWorldService.DlcEventId.EVENT_BUSINESS_STREET_BUFF_REFRESH then
        self:_RefreshBuffs()
    end
end
--endregion

function XUiSkyGardenShoppingStreetAsset:_RefreshAssetByType(com, resType)
    local resInfoNum = self._Control:GetStageResById(resType)
    local resCfgs = self._Control:GetStageResConfigs()
    local cfg = resCfgs[resType]
    com.text = self._Control:GetValueByResConfig(resInfoNum, cfg)
end

function XUiSkyGardenShoppingStreetAsset:_RefreshRes(resType, add)
    if resType then
        local coms = self._ComponentDic[resType]
        if coms then
            self:_RefreshAssetByType(coms[2], resType)

            if add and add ~= 0 and self.TxtGoldChange then
                local resCfgs = self._Control:GetStageResConfigs()
                local cfg = resCfgs[resType]
                local com = self:_GetTextGameObject()
                com.transform.position = coms[4].transform.position
                com.gameObject:SetActive(true)
                com.color = XUiHelper.Hexcolor2Color(cfg.Color)
                com.text = add > 0 and "+" .. add or add
                local animationTr = com.transform:Find("Animation/TxtChangeEnable")
                if animationTr then
                    local anmiationGo = animationTr.gameObject
                    anmiationGo:PlayTimelineAnimation(function()
                        com.gameObject:SetActive(false)
                        self:_RecycleTextGameObject(com)
                    end)
                else
                    com.transform:DOLocalMoveY(40, 0.6):OnComplete(function ()
                        com.gameObject:SetActive(false)
                        self:_RecycleTextGameObject(com)
                    end)
                end
            end
        end
    else
        for _, key in ipairs(self._ResIndex) do
            local value = self._ComponentDic[key]
            self:_RefreshAssetByType(value[2], key)
        end
    end
end

function XUiSkyGardenShoppingStreetAsset:_RefreshBuffs()
    local buffs = self._Control:GetStageGameBuffs(3)
    self.PanelBuff.gameObject:SetActive(buffs and #buffs > 0)
    if not self._BuffsList then self._BuffsList = {} end
    XTool.UpdateDynamicItem(self._BuffsList, buffs, self.GridBuff, XUiSkyGardenShoppingStreetBuffGrid, self)
end

--region 按钮事件
function XUiSkyGardenShoppingStreetAsset:ShowAssetInfo()
    self.BubbleAssetDetail.gameObject:SetActive(true)
    
    local resCfgs = self._Control:GetStageResConfigs()
    if self._ComponentTagPassDic then
        XTool.UpdateDynamicItem(self._PassUis, self._ComponentTagPassDic, self.TagPassenger, XUiSkyGardenShoppingStreetAssetTag, self)
        XTool.UpdateDynamicItem(self._EnvUis, self._ComponentTagEnvDic, self.TagEnvironmental, XUiSkyGardenShoppingStreetAssetTag, self)
    else
        self._ComponentTagPassDic = {
            self._stageResType.AddCustomerFix,
            self._stageResType.AddCustomerRatio
        }
        self._ComponentTagEnvDic = {
            self._stageResType.AddEnvironmentFix,
            self._stageResType.AddEnvironmentRatio,
        }

        self._PassUis = {}
        XTool.UpdateDynamicItem(self._PassUis, self._ComponentTagPassDic, self.TagPassenger, XUiSkyGardenShoppingStreetAssetTag, self)
    
        self._EnvUis = {}
        XTool.UpdateDynamicItem(self._EnvUis, self._ComponentTagEnvDic, self.TagEnvironmental, XUiSkyGardenShoppingStreetAssetTag, self)
    end

    for index, key in ipairs(self._ComponentTagPassDic) do
        local num = self._Control:GetStageResById(key)
        self._PassUis[index]:SetText(self._Control:GetValueByResConfig(num, resCfgs[key], false, true))
    end
    for index, key in ipairs(self._ComponentTagEnvDic) do
        local num = self._Control:GetStageResById(key)
        self._EnvUis[index]:SetText(self._Control:GetValueByResConfig(num, resCfgs[key], false, true))
    end

    XUiManager.CreateBlankArea2Close(self.BubbleAssetDetail.gameObject, function ()
        XTool.UpdateDynamicItem(self._PassUis, nil, self.TagPassenger, XUiSkyGardenShoppingStreetAssetTag, self)
        XTool.UpdateDynamicItem(self._EnvUis, nil, self.TagEnvironmental, XUiSkyGardenShoppingStreetAssetTag, self)
        self.BubbleAssetDetail.gameObject:SetActive(false)
    end)
end

function XUiSkyGardenShoppingStreetAsset:ShowBuffInfo()
    if not self.PanelBuffDetail then return end
    self.PanelBuffDetail.gameObject:SetActive(true)
    if not self._BuffDetailsList then self._BuffDetailsList = {} end
    local buffs = self._Control:GetStageGameBuffs()
    XTool.UpdateDynamicItem(self._BuffDetailsList, buffs, self.GridBuffDetail, XUiSkyGardenShoppingStreetBuffDetailGrid, self)
    if self.ScrollView then
        local size = self.DetailRt.sizeDelta
        size.y = math.min(self.DefaultRtSizeY, #buffs * 160)
        self.DetailRt.sizeDelta = size
    end
    XUiManager.CreateBlankArea2Close(self.PanelBuffDetail.gameObject, function ()
        XTool.UpdateDynamicItem(self._BuffDetailsList, nil, self.GridBuffDetail, XUiSkyGardenShoppingStreetBuffDetailGrid, self)
        self.PanelBuffDetail.gameObject:SetActive(false)
    end)
end
--endregion

--region 私有方法
function XUiSkyGardenShoppingStreetAsset:_RegisterButtonClicks()
    --在此处注册按钮事件
    if not self.PanelAsset then return end
    self.PanelAsset.CallBack = function() self:ShowAssetInfo() end
    self.PanelBuff.CallBack = function() self:ShowBuffInfo() end
end

function XUiSkyGardenShoppingStreetAsset:_AddTextGameObject()
    local go = CS.UnityEngine.Object.Instantiate(self.TxtGoldChange, self.TxtGoldChange.transform.parent)
    return go:GetComponent(typeof(CS.UnityEngine.UI.Text))
end

function XUiSkyGardenShoppingStreetAsset:_GetTextGameObject()
    if not self._changeCache then
        self._changeCache = {}
        return self:_AddTextGameObject()
    end
    if #self._changeCache > 0 then
        return table.remove(self._changeCache, 1)
    end
    return self:_AddTextGameObject()
end

function XUiSkyGardenShoppingStreetAsset:_RecycleTextGameObject(com)
    table.insert(self._changeCache, com)
end
--endregion

return XUiSkyGardenShoppingStreetAsset
