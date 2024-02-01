---@class XAnniversaryAgency : XAgency
---@field private _Model XAnniversaryModel
local XAnniversaryAgency = XClass(XAgency, "XAnniversaryAgency")

--渲染层级
local HiddenLayer=30
local AnniversaryMainSkipId=89047--SkipFunctional中周年主界面的skipId
local AnniversaryDrawId={}

function XAnniversaryAgency:OnInit()
    --初始化一些变量
    self.HiddenLayerMask=math.pow(2,HiddenLayer)
    local drawIdStr=CS.XGame.ClientConfig:GetString('AnniversaryDrawId')
    local drawIdStrs=string.Split(drawIdStr,'|')
    if not XTool.IsTableEmpty(drawIdStrs) then
        for i, v in pairs(drawIdStrs) do
            local drawId = tonumber(v)
            AnniversaryDrawId[drawId] = true
        end
    end
end

function XAnniversaryAgency:InitRpc()
    --实现服务器事件注册
    --XRpc.XXX
end

function XAnniversaryAgency:InitEvent()
    self:AddAgencyEvent(XEventId.EVENT_AWARD_SHOP_ENTER,self.OnRepeatChallengeEnterEvent,self)
    self:AddAgencyEvent(XEventId.EVENT_DRAW_SELECT,self.OnDrawSelectEvent,self)
end

function XAnniversaryAgency:RemoveEvent()
    self:RemoveAgencyEvent(XEventId.EVENT_AWARD_SHOP_ENTER,self.OnRepeatChallengeEnterEvent,self)
    self:RemoveAgencyEvent(XEventId.EVENT_DRAW_SELECT,self.OnDrawSelectEvent,self)
end
----------public start----------
--region 周年回顾截图相关
function XAnniversaryAgency:CreateAlbumControl()
    --1.生成截屏预制体
    local sceneObj=XModelManager.LoadSceneModel(CS.XGame.ClientConfig:GetString('AnniversaryReviewPngCreatorPath'))
    sceneObj:SetLayerRecursively(HiddenLayer)
    local creator=sceneObj.gameObject:GetComponent(typeof(CS.LongPictureCreator))
    if creator==nil then
        XLog.Error('预制体不存在组件：',sceneObj,CS.LongPictureCreator)
        --销毁场景
        CS.UnityEngine.GameObject.Destroy(sceneObj)
        return
    end
    creator:SetCameraRenderLayer(self.HiddenLayerMask)
    --获取相机设置参数
    --PC和移动端两种设置
    local camera = sceneObj.gameObject:GetComponent(typeof(CS.UnityEngine.Camera))
    if camera then
        if CS.UnityEngine.Application.platform == CS.UnityEngine.RuntimePlatform.WindowsEditor or CS.UnityEngine.Application.platform == CS.UnityEngine.RuntimePlatform.WindowsPlayer then
            --PC端不分屏
            camera.targetDisplay = 0
        else
            camera.targetDisplay = 1
        end
    end
    --创建预制体控制器
    local ctrl={
        creatorCom=creator,
        obj=sceneObj,
        Release=function(self)
            CS.UnityEngine.GameObject.Destroy(self.obj)
            self.creatorCom=nil
            self.obj=nil
            self.CreateShortAlbum=nil
            self.CreateLongAlbum=nil
        end,
        CreateShortAlbum=function(self,cb)
            XMVCA.XAnniversary:CreateShortAlbum(self.creatorCom,cb,self)
        end,
        CreateLongAlbum=function(self,cb)
            XMVCA.XAnniversary:CreateLongAlbum(self.creatorCom,cb,self)
        end,
        CanvasContainer={},
        LongImageContainer={},
        ReportContainer={},
    }
    --预制体UI引用
    XTool.InitUiObjectByUi(ctrl.CanvasContainer,sceneObj.transform:Find("Canvas"))
    if ctrl.CanvasContainer.RawImage then
        XTool.InitUiObjectByUi(ctrl.LongImageContainer,ctrl.CanvasContainer.RawImage)
    end
    if ctrl.CanvasContainer.PanelReport then
        XTool.InitUiObjectByUi(ctrl.ReportContainer,ctrl.CanvasContainer.PanelReport)
    end
    return ctrl
end

function XAnniversaryAgency:CreateLongAlbum(creator,cb,control)
    creator:SetSubPictureCount(XTool.GetTableCount(self._Model:GetAnniversaryReviewPictures()))
    creator:SetRawImg(control.CanvasContainer.RawImage)
    creator.ImgPathRequest=function(index)
        --获取配置：
        local cfg=self._Model:GetAnniversaryReviewPictures()[index]

        --设置显示的UI
        for i, v in pairs(control.LongImageUi or {}) do
            v:Close()
        end
        for i, v in pairs(cfg.ScreenShotShowUI or {}) do
            local uicfg=self._Model:GetAnniversaryReviewDataUI()[v]

            if uicfg and control.LongImageUi[uicfg.UiName] then
                control.LongImageUi[uicfg.UiName]:Open()
                control.LongImageUi[uicfg.UiName]:Refresh(uicfg.DataType)
            end
        end
        return self._Model:GetAnniversaryReviewPictures()[index].Address  
    end
    creator:CallRender(function(t2d)
        if cb then
            cb(t2d)
        end
    end)
end

function XAnniversaryAgency:CreateShortAlbum(creator,cb,control)
    creator:SetCameraRenderLayer(self.HiddenLayerMask)
    creator:SetSubPictureCount(1)
    creator:SetRawImg(control.CanvasContainer.PanelReport)
    creator.ImgPathRequest=function(index) return ''  end
    creator:CallRender(function(t2d)
        if cb then
            cb(t2d)
        end
    end)
end

function XAnniversaryAgency:SaveAlbum(t2d,cb)
    local tipFunc = XLuaUiManager.IsUiShow("UiPhotographPortrait") and XUiManager.TipPortraitText or XUiManager.TipText
    XPermissionManager.TryGetPermission(CS.XPermissionEnum.WRITE_EXTERNAL_STORAGE,CS.XTextManager.GetText("PremissionWriteDesc"),function(isWriteGranted, dontTip)
        if not isWriteGranted then
            tipFunc("PremissionDesc")
            XLog.Debug("获取权限错误_NotisWriteGranted")
            return
        end
        local address=CS.XTool.SavePhotoAlbumImg("AnniversaryReview_ScreenShot_forshare",t2d,nil,true,CS.XGame.ClientConfig:GetInt('AnniversaryReviewJPGQuality'))
        cb(address)
    end)
end

function XAnniversaryAgency:SaveAlbumPNG(t2d,cb)
    local tipFunc = XLuaUiManager.IsUiShow("UiPhotographPortrait") and XUiManager.TipPortraitText or XUiManager.TipText
    XPermissionManager.TryGetPermission(CS.XPermissionEnum.WRITE_EXTERNAL_STORAGE,CS.XTextManager.GetText("PremissionWriteDesc"),function(isWriteGranted, dontTip)
        if not isWriteGranted then
            tipFunc("PremissionDesc")
            XLog.Debug("获取权限错误_NotisWriteGranted")
            return
        end
        CS.XTool.SavePhotoAlbumImg("AnniversaryReview_ScreenShot"..XTime.GetLocalNowTimestamp(),t2d,cb)
    end)
    
end

function XAnniversaryAgency:ShareAlbum(address)
    --4.调用分享接口
    local testTopic={}
    for i, v in pairs(self._Model:GetAnniversaryReviewTopics()) do
        testTopic[v.Id]=v.Name
    end
    local result=CS.XAppPlatBridge.KJQShare(address,testTopic)
    --处理分享结果
    if CS.UnityEngine.Application.platform == CS.UnityEngine.RuntimePlatform.WindowsEditor or CS.UnityEngine.Application.platform == CS.UnityEngine.RuntimePlatform.WindowsPlayer then
        XUiManager.TipText('AnniverReviewShareErrCodeInPC')
    elseif result==XEnumConst.Anniversary.ShareResult.Success then
        --分享成功
    elseif result==XEnumConst.Anniversary.ShareResult.ErrCodeUnInstalled then
        XUiManager.TipText('AnniverReviewShareErrCodeUnInstalled')
        XLog.Error('ErrCodeUnInstalled:分享失败，应用未安装')
    elseif result==XEnumConst.Anniversary.ShareResult.ErrCodeInvalidParameter then
        XUiManager.TipText('AnniverReviewShareErrCodeInvalidParameter')
        XLog.Error('ErrCodeInvalidParameter:分享失败，传递参数错误','图片路径:',address,'话题:',testTopic)
    elseif result==XEnumConst.Anniversary.ShareResult.ErrCodeImageExceedsTheSizeLimit then
        XUiManager.TipText('AnniverReviewShareErrCodeImageExceedsTheSizeLimit')
        XLog.Error('ErrCodeImageExceedsTheSizeLimit:分享失败，图片大小超过限制')
    elseif result==XEnumConst.Anniversary.ShareResult.ErrCodeInvalid then
        XUiManager.TipText('AnniverReviewShareErrCodeInvalid')
        XLog.Error('ErrCodeInvalid:分享失败，存在未知的错误')
    end
end
--endregion

function XAnniversaryAgency:GetAnniversaryMainSkipId()
    return AnniversaryMainSkipId
end

function XAnniversaryAgency:GetHadInDrawkey()
    return 'Anniversary4_had_into_draw_'..XPlayer.Id
end

function XAnniversaryAgency:GetHadInRepeatChallengeKey()
    return 'Anniversary4_had_into_repeatChallenge_'..XPlayer.Id
end

--region 活动开启判定

function XAnniversaryAgency:IsActivityInTime(activityid)
    local cfg=self._Model:GetAnniversaryActivity()[activityid]
    if cfg then
        return XFunctionManager.CheckSkipInDuration(cfg.SkipID)
    end
end

function XAnniversaryAgency:IsActivityOutTime(activityid)
    local cfg=self._Model:GetAnniversaryActivity()[activityid]
    if cfg then
        local curTime=XTime.GetServerNowTimestamp()
        local skipCfg=XFunctionConfig.GetSkipFuncCfg(cfg.SkipID)
        --没有配置默认不开放
        if not skipCfg then return true end

        local endTime=0
        if XTool.IsNumberValid(skipCfg.TimeId) then
            endTime=XFunctionManager.GetEndTimeByTimeId(skipCfg.TimeId) or 0
        elseif skipCfg.CloseTime then
            endTime= XTime.ParseToTimestamp(skipCfg.CloseTime)
        else
            --没有时间约束，则默认没有超出活动时间
            return false
        end
        return curTime>=endTime
    end
end

function XAnniversaryAgency:IsActivityConditionSatisfy(activityId)
    local cfg=self._Model:GetAnniversaryActivity()[activityId]
    local isOpen=true
    local desc=''
    if cfg then
        isOpen = XFunctionManager.IsCanSkip(cfg.SkipID)
        local list = XFunctionConfig.GetSkipList(cfg.SkipID)
        if list then
            desc=XFunctionManager.GetFunctionOpenCondition(list.FunctionalId)
        end
    end

    return isOpen,desc
end

function XAnniversaryAgency:JudgeCanOpen(activityid)

    if self:IsActivityOutTime(activityid) then
        --活动已结束
        return false,XUiHelper.GetText('ActivityAlreadyOver')
    elseif self:IsActivityInTime(activityid) then
        return self:IsActivityConditionSatisfy(activityid)
    else
        local cfg=self._Model:GetAnniversaryActivity()[activityid]
        if cfg then
            --活动于xx月xx日开启
            local skipCfg=XFunctionConfig.GetSkipFuncCfg(cfg.SkipID)
            if skipCfg then
                if skipCfg.TimeId then
                    local startTime=XFunctionManager.GetStartTimeByTimeId(skipCfg.TimeId)
                    local dt = CS.XDateUtil.GetLocalDateTime(startTime)
                    return false,XUiHelper.GetText('ActivityOpenMonthDayTime',dt.Month,dt.Day)
                else
                    return false,XUiHelper.GetText('ActivityAlreadyOver')
                end
            end

        end

    end
end
--endregion
----------public end----------

----------private start----------

function XAnniversaryAgency:OnRepeatChallengeEnterEvent()
    XSaveTool.SaveData(self:GetHadInRepeatChallengeKey(),true)
end

function XAnniversaryAgency:OnDrawSelectEvent(drawId)
    --如果选择的是周年卡池
    if AnniversaryDrawId[drawId] then
        XSaveTool.SaveData(self:GetHadInDrawkey(),true)
    end
end

----------private end----------

return XAnniversaryAgency