local type = type

local XUiTip = XLuaUiManager.Register(XLuaUi, "UiTip")

function XUiTip:OnAwake()
    self:InitAutoScript()
end

function XUiTip:OnStart(data, hideSkipBtn, rootUiName, lackNum, showNum)
    local musicKey = self:GetAutoKey(self.BtnBack, "onClick")
    self.SpecialSoundMap[musicKey] = XSoundManager.UiBasicsMusic.Return
    self.HideSkipBtn = hideSkipBtn
    self.RootUiName = rootUiName
    self.Data = data
    self.LackNum = lackNum
    self.ShowNum = showNum -- 兼容自定义数量
    self:PlayAnimation("AnimStart")
end

function XUiTip:OnEnable()
    self:Refresh(self.Data)
end

-- auto
-- Automatic generation of code, forbid to edit
function XUiTip:InitAutoScript()
    self.SpecialSoundMap = {}
    self:AutoAddListener()
end

function XUiTip:GetAutoKey(uiNode, eventName)
    if not uiNode then
        return
    end
    return eventName .. uiNode:GetHashCode()
end

function XUiTip:RegisterListener(uiNode, eventName, func)
    local key = self:GetAutoKey(uiNode, eventName)
    if not key then
        return
    end
    local listener = self.AutoCreateListeners[key]
    if listener ~= nil then
        uiNode[eventName]:RemoveListener(listener)
    end

    if func ~= nil then
        if type(func) ~= "function" then
            XLog.Error("XUiTip:RegisterListener函数错误, 参数func需要是function类型, func的类型是" .. type(func))
        end

        listener = function(...)
            XSoundManager.PlayBtnMusic(self.SpecialSoundMap[key], eventName)
            func(self, ...)
        end

        uiNode[eventName]:AddListener(listener)
        self.AutoCreateListeners[key] = listener
    end
end

function XUiTip:AutoAddListener()
    self.AutoCreateListeners = {}
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick)
    self:RegisterClickEvent(self.BtnGet, self.OnBtnGetClick)
    self:RegisterClickEvent(self.BtnOk, self.OnBtnOkClick)
    self:RegisterClickEvent(self.BtnTcanchaungBlack, self.OnBtnTcanchaungBlackClick)
end
-- auto
function XUiTip:OnBtnBackClick()
    self:Close()
end

function XUiTip:OnBtnGetClick()
    XLuaUiManager.Open(
        "UiSkip",
        self.TemplateId,
        function()
            self:Close()
        end,
        self.HideSkipBtn
    )
end

function XUiTip:OnBtnOkClick()
    self:Close()
end

function XUiTip:OnBtnTcanchaungBlackClick()
    local buyAssetTemplate = XDataCenter.ItemManager.GetBuyAssetTemplateById(self.TemplateId)

    -- 判断配置表是否存在快捷购买数据
    if not buyAssetTemplate then
        XUiManager.TipMsg(CS.XTextManager.GetText("ShopNoGoodsDesc"), XUiManager.UiTipType.Tip)
    else
        XLuaUiManager.Open("UiBuyAsset", self.TemplateId, nil, nil, self.LackNum)
    end
end

function XUiTip:SetUiActive(ui, active)
    if not ui or not ui.gameObject then
        return
    end

    if ui.gameObject.activeSelf == active then
        return
    end

    ui.gameObject:SetActive(active)
end

function XUiTip:ResetUi()
    self:SetUiActive(self.TxtCount, false)
    self:SetUiActive(self.TxtName, false)
    self:SetUiActive(self.ImgQuality, false)
    self:SetUiActive(self.TxtWorldDesc, false)
    self:SetUiActive(self.TxtDescription, false)
    self:SetUiActive(self.BtnGet, false)
    self:SetUiActive(self.CountTitle, false)
end

-- data 可以是 XItemData / XEquipData / XCharacterData / XFashionData
function XUiTip:Refresh(data)
    self.Data = data
    if not data then
        XLog.Error("XUiTip:Refresh错误: 参数data不能为空")
        return
    end

    self:ResetUi()
    if type(data) == "number" then
        self.TemplateId = data
    else
        if data.IsTempItemData then
            self:SetTempData(data)
            return
        end
        self.TemplateId = data.TemplateId and data.TemplateId or data.Id
    end

    if
        self.TemplateId == XDataCenter.ItemManager.ItemId.AndroidHongKa or
            self.TemplateId == XDataCenter.ItemManager.ItemId.IosHongKa
     then
        self.TemplateId = XDataCenter.ItemManager.ItemId.HongKa
    end

    local goodsShowParams = XGoodsCommonManager.GetGoodsShowParamsByTemplateId(self.TemplateId)

    -- 获取途径按钮
    local skipIdParams = XGoodsCommonManager.GetGoodsSkipIdParams(self.TemplateId)
    if skipIdParams and #skipIdParams > 0 then
        self:SetUiActive(self.BtnGet, true)
    end

    -- 快捷兑换按钮
    if
        XDataCenter.ItemManager.IsFastTrading(self.TemplateId) and
            XDataCenter.ItemManager.JudjeCanFastTrading(self.RootUiName)
     then
        self:SetUiActive(self.BtnTcanchaungBlack, true)
    end

    -- 名称
    if self.TxtName and goodsShowParams.Name then
        self.TxtName.text = goodsShowParams.Name
        self:SetUiActive(self.TxtName, true)
    end

    -- 数量
    if self.TxtCount then
        local count = nil
        if self.ShowNum then
            count = self.ShowNum
        else
            count = XGoodsCommonManager.GetGoodsCurrentCount(self.TemplateId)
        end
        self.TxtCount.text = count or 0
        self:SetUiActive(self.TxtCount, true)
        self:SetUiActive(self.CountTitle, true)
    end

    -- 图标
    if self.RImgIcon and self.RImgIcon:Exist() then
        local icon = goodsShowParams.Icon

        if goodsShowParams.BigIcon then
            icon = goodsShowParams.BigIcon
        end

        if icon and #icon > 0 then
            self.RImgIcon:SetRawImage(icon)
            self:SetUiActive(self.RImgIcon, true)
        end
    end

    -- 特效
    if self.HeadIconEffect then
        local effect = goodsShowParams.Effect
        if effect then
            self.HeadIconEffect.gameObject:LoadPrefab(effect)
            self.HeadIconEffect.gameObject:SetActiveEx(true)
            self.HeadIconEffect:Init()
        else
            self.HeadIconEffect.gameObject:SetActiveEx(false)
        end
    end

    -- 品质底图
    if self.ImgQuality and goodsShowParams.Quality then
        XUiHelper.SetQualityIcon(self, self.ImgQuality, goodsShowParams.Quality)
        self:SetUiActive(self.ImgQuality, true)
    end

    -- 世界观描述
    if self.TxtWorldDesc then
        local worldDesc = XGoodsCommonManager.GetGoodsWorldDesc(self.TemplateId)
        if worldDesc and #worldDesc then
            self.TxtWorldDesc.text = string.gsub(worldDesc, "\\n", "\n");
            self:SetUiActive(self.TxtWorldDesc, true)
        end
    end

    -- 描述
    if self.TxtDescription then
        local desc = XGoodsCommonManager.GetGoodsDescription(self.TemplateId)
        if desc and #desc > 0 then
            self.TxtDescription.text = desc
            self:SetUiActive(self.TxtDescription, true)
        end
    end
end
--===============
--显示临时道具(非背包道具或者需要改数据的道具)
--===============
function XUiTip:SetTempData(data)
    -- 名称
    if self.TxtName and data.Name then
        self.TxtName.text = data.Name
        self:SetUiActive(self.TxtName, true)
    end
    -- 数量
    if self.TxtCount and data.Count then
        -- data.Count 可能会与 XUiGridCommon 冲突
        self.TxtCount.text = data.OwnCount or data.Count
        self:SetUiActive(self.TxtCount, true)
        self:SetUiActive(self.CountTitle, true)
    end
    -- 图标
    if self.RImgIcon and self.RImgIcon:Exist() and data.Icon then
        self.RImgIcon:SetRawImage(data.Icon)
        self:SetUiActive(self.RImgIcon, true)
    end
    -- 品质底图
    if self.ImgQuality and data.Quality then
        XUiHelper.SetQualityIcon(self, self.ImgQuality, data.Quality)
        self:SetUiActive(self.ImgQuality, true)
    end
    -- 世界观描述
    if self.TxtWorldDesc and data.WorldDesc then
        self.TxtWorldDesc.text = data.WorldDesc
        self:SetUiActive(self.TxtWorldDesc, true)
    end
    -- 描述
    if self.TxtDescription and data.Description then
        self.TxtDescription.text = data.Description
        self:SetUiActive(self.TxtDescription, true)
    end

    -- 获取途径按钮
    local skipIdParams = data.TemplateId and XGoodsCommonManager.GetGoodsSkipIdParams(data.TemplateId)
    if skipIdParams and #skipIdParams > 0 then
        self.TemplateId = data.TemplateId
        self:SetUiActive(self.BtnGet, true)
    end
end

function XUiTip:OnGetEvents()
    return {
        XEventId.EVENT_ITEM_FAST_TRADING
    }
end

function XUiTip:OnNotify(evt, ...)
    if evt == XEventId.EVENT_ITEM_FAST_TRADING then
        self:Refresh(self.Data)
        local arg = {...}
        --购买后，调整缺少数量
        local lackNum = arg[1]
        if lackNum then
            self.LackNum = lackNum
        end
    end
end
