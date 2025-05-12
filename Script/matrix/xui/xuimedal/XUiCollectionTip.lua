local XUiCollectionTip = XLuaUiManager.Register(XLuaUi, "UiCollectionTip")
local HintColor = CS.XGame.ClientConfig:GetString("CollectionHintColor")
local Json = require("XCommon/Json")
local XUiCollectionStyle = require("XUi/XUiMedal/XUiCollectionStyle")

function XUiCollectionTip:OnStart(data, inType, onOpenCallBack)
    self.Data = data
    self.InType = inType
    self.CollectionStyleDic = {}    -- Key:收藏品Id  Value:XUiCollectionStyle脚本

    self.BtnClose.CallBack = function()
        self:Close()
    end
    self.TxtHint = { self.TxtHint1, self.TxtHint2, self.TxtHint3, self.TxtHint4 }
    self.OpenCb = onOpenCallBack
    self:SetDetail()
end

function XUiCollectionTip:OnEnable()
    if self.OpenCb then
        self.OpenCb()
    end
end

function XUiCollectionTip:SetDetail()
    if self.InType ~= XDataCenter.MedalManager.InType.OtherPlayer then
        XDataCenter.MedalManager.SetMedalForOld(self.Data.Id, self.Data.Type)
    end
    self:SetDetailData()
    self:ShowLock(self.Data.IsLock)
end

function XUiCollectionTip:ShowLock(IsLock)
    self.RImgIconLock.gameObject:SetActiveEx(IsLock)
    self.ImgConditionUnlock.gameObject:SetActiveEx(not IsLock)
end

function XUiCollectionTip:SetDetailData()
    self.TxtCollectionName.text = self.Data.Name

    if self.Data.Id ~= XEnumConst.SpecialHandling.DEADCollectiblesId 
        and self.Data.Id ~= XEnumConst.SpecialHandling.ShotrolCollectiblesId then
        self.TxtInfo.text = self.Data.WorldDesc
    else
        if self.Data.Id == XEnumConst.SpecialHandling.DEADCollectiblesId then
            self.TxtInfo.text = XUiHelper.ReplaceUnicodeSpace(self.Data.WorldDesc)
        else
            self.TxtInfo.text = self.Data.WorldDesc
        end
        self.TxtCollectionName.resizeTextForBestFit = true
    end
    self.TxtCondition.text = self.Data.GetDesc

    local styleObj = self.CollectionStyleNode.gameObject:LoadPrefab(self.Data.PrefabPath)
    self.CollectionStyleDic[self.Data.Id] = XUiCollectionStyle.New(styleObj, self.Data)

    if self.Data.MedalImg ~= nil then
        self.RImgIconLock:SetRawImage(self.Data.MedalImg)
    end

    local levelIcon = XDataCenter.MedalManager.GetLevelIcon(self.Data.Id, self.Data.Quality)
    if levelIcon then
        self:SetUiSprite(self.IconLevel, levelIcon)
        self.IconLevel.gameObject:SetActiveEx(true)
    else
        self.IconLevel.gameObject:SetActiveEx(false)
    end

    if  self.Data.ExpandInfo then
        -- 拥有服务器下发的扩展信息
        for _, text in pairs(self.TxtHint) do
            text.gameObject:SetActiveEx(false)
        end

        if self.Data.Type == XMedalConfigs.MedalType.Anniversary then
            -- 周年庆收藏品
            local jsonFormatData = Json.decode(self.Data.ExpandInfo)

            for index, text in pairs(self.TxtHint) do
                if self.Data.ExpandInfoId[index] then
                    local hintText
                    local serverKey = XMedalConfigs.GetExpandInfoStrServerKeyById(self.Data.ExpandInfoId[index])
                    local data = jsonFormatData[serverKey]
                    if  data == 0 then
                        -- 数据为空
                        hintText = XMedalConfigs.GetExpandInfoEmptyDescById(self.Data.ExpandInfoId[index])
                    else
                        -- 解析数据
                        local dataTxt
                        if serverKey == XMedalConfigs.ExpandInfoType.CreateTime then
                            -- 首次进入游戏的时间
                            dataTxt = XTime.TimestampToLocalDateTimeString(data, "yyyy年MM月dd日")
                        elseif serverKey == XMedalConfigs.ExpandInfoType.MaxAssignChapter then
                            -- 边界公约最高通关章节
                            local chapterData = XDataCenter.FubenAssignManager.GetChapterDataById(data)
                            dataTxt = chapterData:GetName()
                        elseif serverKey == XMedalConfigs.ExpandInfoType.MaxCharacterLiberateLvCount then
                            -- 解放角色数
                            dataTxt = data
                        elseif serverKey == XMedalConfigs.ExpandInfoType.MaxFubenBfrt then
                            -- 据点最高通关章节
                            dataTxt = XDataCenter.BfrtManager.GetChapterName(data)
                        else
                            XLog.Error("XUiCollectionTip:SetDetailData函数错误，serverKey没有对应的类型")
                            return
                        end
                        hintText = string.format(XMedalConfigs.GetExpandInfoDescById(self.Data.ExpandInfoId[index]), dataTxt)
                    end
                    text.text = hintText
                    text.gameObject:SetActiveEx(true)
                else
                    text.gameObject:SetActiveEx(false)
                end
            end
        end
    else
        for index, text in pairs(self.TxtHint) do
            if self.Data.Hint[index] then
                text.text = self.Data.Hint[index]
                text.gameObject:SetActiveEx(true)
                if self.Data.Quality - self.Data.InitQuality >= index then
                    text.color = XUiHelper.Hexcolor2Color(HintColor)
                end
            else
                text.gameObject:SetActiveEx(false)
            end
        end
    end

    if self.Data.Type == XMedalConfigs.MedalType.Experience then
        local curLevel, nextExp, exScore = XMedalConfigs.GetSpecialCollectionCurLevelAndNextScoreByScore(self.Data.Id, self.Data.Score)
        self.TextLevel.text = CS.XTextManager.GetText("SpecialCollectionLevel", curLevel)
        self.TextNum.text = string.format("%d/%d", math.min((self.Data.Score - exScore), nextExp), nextExp)
        self.ImageExp.fillAmount = math.min((self.Data.Score - exScore), nextExp) / nextExp
        self.PanelLevel.gameObject:SetActiveEx(true)
    else
        self.PanelLevel.gameObject:SetActiveEx(false)
    end
end
