local XUiGuildBuild = XLuaUiManager.Register(XLuaUi, "UiGuildBuild")
local XUiGuildViewSetHeadPortrait = require("XUi/XUiGuild/XUiChildView/XUiGuildViewSetHeadPortrait")
local NameLenMinLimit
local NameLenMaxLimit
local GuildDeclarMaxLen
local greyColor = CS.XTextManager.GetText("GuildBuildEnoughColor")
local redColor = CS.XTextManager.GetText("GuildBuildNotEnoughColor")
local CSUnityColorWhite = CS.UnityEngine.Color.white

function XUiGuildBuild:OnAwake()
    NameLenMinLimit = CS.XGame.Config:GetInt("GuildNameMinLen")
    NameLenMaxLimit = CS.XGame.Config:GetInt("GuildNameMaxLen")
    GuildDeclarMaxLen = CS.XGame.Config:GetInt("GuildDeclarationMaxLen")
    self.CurGuildIconId = 1
    --v1.27-公会优化-创建所需资源配置迁移
    self.AllCoins = XGuildConfig.GetCreateCostItemType()
    self.AllCosts = XGuildConfig.GetCreateCostItemCount()

    self.GuildViewSetHeadPortrait = XUiGuildViewSetHeadPortrait.New(self.PanelSetHeadPotrait, self, true)
    self.DefaultGuildIconColor = self.GuildFaceIcon.color
    self:InitFun()
end

function XUiGuildBuild:OnGetEvents()
    return {
        XEventId.EVENT_GUILD_FILTER_FINISH,
    }
end

function XUiGuildBuild:OnNotify(evt, ...)
    if evt == XEventId.EVENT_GUILD_FILTER_FINISH  then
        self:OnGuildFilterFinish(...)
    end
end

function XUiGuildBuild:OnEnable()
    self:OnRefresh()
    
    for i = 1, #self.AllCoins do
        local coin = tonumber(self.AllCoins[i])
        local needNum = tonumber(self.AllCosts[i])
        local ownNum = XDataCenter.ItemManager.GetCount(coin)

        local color = (ownNum >= needNum) and greyColor or redColor
        self[string.format("TxtSpend%d", i)].text = string.format("<color=%s>%d</color>", color, needNum)
        self[string.format("RImgSpend%d", i)]:SetRawImage(XDataCenter.ItemManager.GetItemIcon(coin))
    end
    self.TxtHint.text = CS.XTextManager.GetText("GuildDeclarationHintText")
end

function XUiGuildBuild:OnDisable()

    if self.IsBuildSuccess then
        self.IsBuildSuccess = false
        XLuaUiManager.Close("UiGuildRecommendation")
    end
end

function XUiGuildBuild:InitFun()
    self.BtnCancel.CallBack = function() self:OnBtnCancelClick() end
    self.BtnConfirm.CallBack = function() self:OnBtnConfirmClick() end
    self.BtnHeadIcon.CallBack = function() self:OnBtnHeadIconClick() end
end

function XUiGuildBuild:OnBtnHeadIconClick()
    self.GuildViewSetHeadPortrait:OnRefresh(self.CurGuildIconId)
    self.PanelSetHeadPotrait.gameObject:SetActiveEx(true)
end

function XUiGuildBuild:OnGuildFilterFinish(guildName, guilaDecl)
    self.GuidNameInputField.text = guildName
    self.GuildDeclarationInputField.text = guilaDecl
end
function XUiGuildBuild:OnBtnConfirmClick()
    if not self.GuidNameInputField or not self.GuidNameInputField.textComponent then
        return
    end

    local guildName = self.GuidNameInputField.text

    if string.match(guildName,"%s") then
        XUiManager.TipText("GuildNameSpecialTips",XUiManager.UiTipType.Wrong)
        return
    end

    local utf8Count = self.GuidNameInputField.textComponent.cachedTextGenerator.characterCount - 1
    if utf8Count < NameLenMinLimit then
        local text = CS.XTextManager.GetText("GuildNameMinNameLengthTips",NameLenMinLimit)
        XUiManager.TipMsg(text, XUiManager.UiTipType.Wrong)
        return
    end

    if utf8Count > NameLenMaxLimit then
        local text = CS.XTextManager.GetText("GuildNameMaxNameLengthTips",NameLenMaxLimit)
        XUiManager.TipMsg(text, XUiManager.UiTipType.Wrong)
        return
    end

    if not self.GuildDeclarationInputField or not self.GuildDeclarationInputField.textComponent then
        return
    end
    
    local declaration = self.GuildDeclarationInputField.text
    local tmpUtf8Count = self.GuildDeclarationInputField.textComponent.cachedTextGenerator.characterCount - 1
    if tmpUtf8Count > GuildDeclarMaxLen then
        local text = CS.XTextManager.GetText("GuildDelarationMaxNameLengthTips",GuildDeclarMaxLen)
        XUiManager.TipMsg(text, XUiManager.UiTipType.Wrong)
        return
    end

    if string.match(declaration,"%s") then
        XUiManager.TipText("GuildDeclarationSpecialTips",XUiManager.UiTipType.Wrong)
        return
    end

    if declaration == "" then
        declaration = CS.XTextManager.GetText("GuildDeclarationDefaultText")
    end

    -- 消耗判断
    local costStr = ""
    for i = 1, #self.AllCoins do
        local coin = tonumber(self.AllCoins[i])
        local needNum = tonumber(self.AllCosts[i])
        local ownNum = XDataCenter.ItemManager.GetCount(coin)
        local coinName = XDataCenter.ItemManager.GetItemName(coin)
        costStr = string.format("%s%d%s,", costStr, needNum, coinName)
        if needNum > ownNum then
            XUiManager.TipText("GuildBuildNotEnoughCosts",XUiManager.UiTipType.Wrong)
            return
        end
    end

    local title = CS.XTextManager.GetText("GuildBuildGuildTitle")
    local content = CS.XTextManager.GetText("GuildBuildGuildContent", costStr)
    XUiManager.DialogTip(title, content, XUiManager.DialogType.Normal, nil, function()
        XDataCenter.GuildManager.BuildGuildRequest(guildName, declaration, self.CurGuildIconId, function()
            self.IsBuildSuccess = true
            self:Close()
            XLuaUiManager.Remove("UiGuildBuild")

            XUiManager.TipText("GuildBuildSuccessTips")
            XDataCenter.GuildManager.GetGuildDetails(0, function()
                XDataCenter.GuildDormManager.EnterGuildDorm()
            end)
        end)
    end)
end

function XUiGuildBuild:OnBtnCancelClick()
    self:Close()
end

function XUiGuildBuild:RecordGuildIconId(iconId)
    self.CurGuildIconId = iconId
    self:OnRefresh()
end

-- 更新数据
function XUiGuildBuild:OnRefresh()
    if self.CurGuildIconId ~= self.PreGuildIconId then
        local cfg = XGuildConfig.GetGuildHeadPortraitById(self.CurGuildIconId)
        if cfg then
            self.GuildFaceIcon:SetRawImage(cfg.Icon)
            if cfg.IsSpecial then
                self.GuildFaceIcon.color = CSUnityColorWhite
                self.RImgSpecialHeadBg.gameObject:SetActiveEx(true)
                self.RImgSpecialHeadBg:SetRawImage(cfg.CreateGuildBg)
            else
                self.GuildFaceIcon.color = self.DefaultGuildIconColor
                self.RImgSpecialHeadBg.gameObject:SetActiveEx(false)
            end
            self.PreGuildIconId = self.CurGuildIconId
        end
    end
end
