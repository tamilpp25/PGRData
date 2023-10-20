---@class XAnniversaryAgency : XAgency
---@field private _Model XAnniversaryModel
local XAnniversaryAgency = XClass(XAgency, "XAnniversaryAgency")

--渲染层级
local HiddenLayer=30

function XAnniversaryAgency:OnInit()
    --初始化一些变量
    self.HiddenLayerMask=math.pow(2,HiddenLayer)
end

function XAnniversaryAgency:InitRpc()
    --实现服务器事件注册
    --XRpc.XXX
end

function XAnniversaryAgency:InitEvent()
    --实现跨Agency事件注册
    --self:AddAgencyEvent()
end

----------public start----------

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

    --返回预制体控制器
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
            XMVCA.XAnniversary:CreateShortAlbum(self.creatorCom,cb)
        end,
        CreateLongAlbum=function(self,cb)
            XMVCA.XAnniversary:CreateLongAlbum(self.creatorCom,cb)
        end
    }
    return ctrl
end

function XAnniversaryAgency:CreateLongAlbum(creator,cb)
    creator:SetSubPictureCount(XTool.GetTableCount(self._Model:GetAnniversaryReviewPictures()))
    creator.ImgPathRequest=function(index) return self._Model:GetAnniversaryReviewPictures()[index].Address  end
    creator:CallRender(function(t2d)
        if cb then
            cb(t2d)
        end
    end)
end

function XAnniversaryAgency:CreateShortAlbum(creator,cb)
    --todo:暂时没有短图生成的UI支持
    if cb then
        cb(nil)
    end
    if true then
        return
    end
    --todo:设置生成短图用的Ui
    creator:SetCameraRenderLayer(self.HiddenLayerMask)
    creator:SetSubPictureCount(1)
    creator.ImgPathRequest=function(index) return ''  end
    creator:CallRender(function(t2d)
        if cb then
            cb(t2d)
        end
    end)
end

function XAnniversaryAgency:SaveAlbum(t2d)
    local address=CS.XTool.SavePhotoAlbumImg("AnniversaryReview_ScreenShot",t2d,nil,true,CS.XGame.ClientConfig:GetInt('AnniversaryReviewJPGQuality'))
    return address
end

function XAnniversaryAgency:ShareAlbum(address)
    --4.调用分享接口
    local testTopic={}
    for i, v in pairs(self._Model:GetAnniversaryReviewTopics()) do
        testTopic[v.Id]=v.Name
    end
    local result=CS.XAppPlatBridge.KJQShare(address,testTopic)
    --处理分享结果
    if result==XEnumConst.Anniversary.ShareResult.Success then
        --分享成功
    elseif result==XEnumConst.Anniversary.ShareResult.ErrCodeUnInstalled then
        XLog.Error('ErrCodeUnInstalled:分享失败，应用未安装')
    elseif result==XEnumConst.Anniversary.ShareResult.ErrCodeInvalidParameter then
        XLog.Error('ErrCodeInvalidParameter:分享失败，传递参数错误','图片路径:',address,'话题:',testTopic)
    elseif result==XEnumConst.Anniversary.ShareResult.ErrCodeImageExceedsTheSizeLimit then
        XLog.Error('ErrCodeImageExceedsTheSizeLimit:分享失败，图片大小超过限制')
    elseif result==XEnumConst.Anniversary.ShareResult.ErrCodeInvalid then
        XLog.Error('ErrCodeInvalid:分享失败，存在未知的错误')
    end
end

----------public end----------

----------private start----------


----------private end----------

return XAnniversaryAgency