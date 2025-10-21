<?php

namespace app\controllers;

use Yii;
use yii\web\Controller;
use yii\web\NotFoundHttpException;
use yii\filters\VerbFilter;
use app\models\Satisfisleri;
use app\models\Satissatirlari;
use app\components\Dia;
use app\models\Iadefisleri;
use app\models\Iadesatirlari;
use app\models\Carihareketler;
use app\models\Satiscilar;
use app\models\Musteriler;
use app\models\Urunler;
use app\models\SatinAlmasiparisFis;
/**
 * LocationsController implements the CRUD actions for Locations model.
 */

class ApimobilController extends Controller
{
    /**
     * @inheritDoc
     */
    public function behaviors()
    {
        $behaviors = parent::behaviors();
        $behaviors['corsFilter'] = [

            'class' => \yii\filters\Cors::className(),

            'cors' => [

                'Origin' => ['*'],

                'Access-Control-Allow-Origin' => [ '*'],

                'Access-Control-Request-Method' => [
                    'GET',
                    'POST',
                    'PUT',
                    'PATCH',
                    'HEAD',
                    'OPTIONS'
                ],

                'Access-Control-Request-Headers' => [ '*'],

                'Access-Control-Allow-Credentials' => null,

                'Access-Control-Max-Age' => 86400,

                'Access-Control-Expose-Headers' => []
            ]
        ];

        return $behaviors;
    }
    public function beforeAction($action)
    {
        if (    $action->id == 'login'||
                $action->id == 'iade' ||
                $action->id == 'satis' ||
                $action->id == 'bankatahsilat'||
                $action->id == 'cektahsilat'||
                $action->id == 'nakittahsilat' ||
                $action->id == 'kredikartitahsilat' ) {
            $this->enableCsrfValidation = false;
        }
        return parent::beforeAction($action);
    }

    function convertToStandardDateTime($inputDate) {
        // Gelen format: "d.m.Y H:i:s"
        $dateTime = \DateTime::createFromFormat('d.m.Y H:i:s', $inputDate);
        if ($dateTime === false) {
            return null; // Hatalı tarih formatı
        }
        return $dateTime->format('Y-m-d H:i:s');
    }

    public function actionTest(){
        $this->layout=false;
        // $tahsilat=Carihareketler::find()->where(["HareketId"=>185])->one();
        // Dia::tahsilatgonder($tahsilat);
        //$fis=Satisfisleri::find()->where(["FisNo"=>"MO2507240644"])->one();
        // $satirlar=$fis->getSatissatirlari()->all();
        // $sira=0;
        // foreach ($satirlar as $satir) {
        //     $sd=[];

        //     $stok = null;
        //     $birimAlani = null;

        //     if ($satir instanceof \app\models\SatinAlmaSiparisFisSatir) { // Satınalma sipariş satırı ise
        //         if (!$satir->urun) continue; // İlişkili ürün yoksa atla
        //         $stok = $satir->urun;
        //         $birimAlani = $satir->birim; // birim alanı kullanılıyor
        //     } else { // Satış sipariş satırı ise (varsayılan)
        //         $stok = Urunler::find()->where(["StokKodu" => $satir->StokKodu])->one();
        //         if (!$stok) continue;
        //         $birimAlani = $satir->BirimTipi; // BirimTipi alanı olduğu varsayılıyor
        //     }

        //     if($birimAlani=="UNIT")
        //         $birimkey=$stok->BirimKey1;
        //     else
        //         $birimkey=$stok->BirimKey2;

        //     $satirtutari=0;//$satir->BirimFiyat*$satir->Miktar*(1-$satir->Iskonto/100);
        //     $satirkdv=0;//$satirtutari*$satir->vat/100;
        //     $sd=[
        //         "_key_kalemturu" => ["stokkartkodu" => $stok->StokKodu],
        //         "_key_scf_kalem_birimleri" => $birimkey,
        //             "_key_sis_depo_source" => ["depokodu" => "44.03.01"],
        //             "_key_sis_doviz" => ["adi" => "GBP"],
        //             "anamiktar" =>$satir->Miktar,
        //             "birimfiyati" =>$satir->BirimFiyat??0,
        //             "dovizkuru" => "1.000000",
        //             "kalemturu" => "MLZM",
        //             "kdv" =>  $stok->Vat,
        //             "kdvdurumu" => "H",
        //             "kdvtutari" =>$satirkdv,
        //             "miktar" =>  $satir->Miktar,
        //             "onay" => "KABUL",
        //             "rezervasyon" => "H",
        //             "siptarih" => $fis->Fistarihi,
        //             "sirano" => $sira,
        //             "sonbirimfiyati" => $satir->BirimFiyat??0,
        //             "tutari" => $satirtutari,
        //             "yerelbirimfiyati" => $satir->BirimFiyat??0,
        //         "m_varyantlar" => []
        //     ];
        //     $kalemler[]=$sd;
        //     $sira++;

        // }
        // Yii::$app->response->format = \yii\web\Response::FORMAT_JSON;
        // return $kalemler;
        //Dia::siparisgondermobil($fis,2);
        echo    strtoupper("Unit");
    }

    public function actionLogin()
    {
        Yii::$app->response->format = \yii\web\Response::FORMAT_JSON;

        $request = Yii::$app->request;
        $username = $request->post('username');
        $password = $request->post('password');


        $sp=Satiscilar::find()->where(["kodu"=>$username])->andWhere(['password'=>$password])->one();
        if ($sp) {
            // basit bir API key üretimi
            $apiKey = hash('sha256', uniqid('apikey_', true));

            // geçici olarak cache'e kaydet (örnek amaçlı)
            Yii::$app->cache->set("apikey_$username", $apiKey, 3600 * 24); // 24 saat geçerli
            Yii::$app->cache->set("apikey_reverse_$apiKey", $username, 3600 * 24);
            return [
                'status' => 'success',
                'message' => 'Login successful',
                'apikey' => $apiKey,
                "prefix"=>"MBL"
            ];
        } else {
            return [
                'status' => 'error',
                'message' => 'Invalid username or password'
            ];
        }
    }



    private function getApikey($apiKey){
        $apiKey = is_string($apiKey) ? $apiKey : '';
        if (str_starts_with($apiKey, 'Bearer ')) {
            $apiKey = trim(str_replace('Bearer', '', $apiKey));
        }
        $username = Yii::$app->cache->get("apikey_reverse_$apiKey");
        if($username)
            return $username;
        else
            return false;
        // $storedApiKey = Yii::$app->cache->get("apikey_mobil");
        // if ($apiKey === $storedApiKey) {
        //     return true;
        // } else {
        //     // yetkisiz erişim
        //     return false;
        // }

    }

    public function actionGetnewcustomer($time){
        $this->layout = false;
        Yii::$app->response->format = \yii\web\Response::FORMAT_JSON;
        $apiKey = Yii::$app->request->headers->get('Authorization');
        $satisci=$this->getApikey( $apiKey );

        $dateString = str_replace('%20', ' ', $time);
        $date = \DateTime::createFromFormat('d.m.Y H:i:s', $dateString);

        if ($date) {
            $tarih=$date->format('Y.m.d H:i:s'); // 2024.05.01 15:55:30
        } else {
             return [
                "status"=>0,
                "hata"=>"Geçersiz tarih ve zaman formatı"
            ];
        }

        if(!$satisci)
        return  ['IsSuccessStatusCode'=>false,'status' => 'error', 'message' =>"Eksik veya Hatalı Apikey"];

        $stoklar=Yii::$app->db->createCommand('SELECT
        VergiNo, VergiDairesi, Adres, Telefon, Email, Kod,
        Unvan,postcode as PostCode,Aktif
            FROM musteriler WHERE Aktif=1 and satiselemani=:st AND  created_at > :time', [":st"=>$satisci,'time' => $tarih])->queryAll();

        return [
            "status"=>1,
            "customers"=>$stoklar
        ];

    }

   public function actionGetupdatedcustomer($time){
        $this->layout = false;
        Yii::$app->response->format = \yii\web\Response::FORMAT_JSON;
        $apiKey = Yii::$app->request->headers->get('Authorization');
        if($this->getApikey( $apiKey )){
            $stoklar=Yii::$app->db->createCommand('SELECT
            VergiNo, VergiDairesi, Adres, Telefon, Email, Kod,
            Unvan,postcode as PostCode,Aktif
             FROM musteriler WHERE  Aktif=1 AND  updated_at > :time and created_at<:time', ['time' =>$this->convertToStandardDateTime($time)])->queryAll();
            return [
                "status"=>1,
                "customers"=>$stoklar
        ];
        }
        else
            return [
                    "status"=>false,
                    "message"=>"invalid token"
            ];

    }

    public function actionGetnewproducts($time){
        $this->layout = false;
        Yii::$app->response->format = \yii\web\Response::FORMAT_JSON;
        $apiKey = Yii::$app->request->headers->get('Authorization');

        if($this->getApikey( $apiKey )){
            $stoklar=Yii::$app->db->createCommand('SELECT StokKodu,fiyat4 as AdetFiyati,fiyat5 as KutuFiyati, Pm1, Pm2, Pm3,
            Barcode1, Barcode2, Barcode3, Vat, Barcode4,
               UrunAdi,Birim1,BirimKey1,Birim2,BirimKey2,Aktif,imsrc, qty as miktar
            FROM urunler WHERE aktif=1 and created_at > :time', ['time' => $this->convertToStandardDateTime($time)])->queryAll();
            foreach ($stoklar as &$stok) {
                $stok['AdetFiyati'] = (string) $stok['AdetFiyati'];
                $stok['KutuFiyati'] = (string) $stok['KutuFiyati'];
            }
            return [
                "status"=>1,
                "customers"=>$stoklar
             ];
        }
        else
            return [
                    "status"=>false,
                    "message"=>"invalid token"
            ];

    }
    public function actionGetupdatedproducts($time){
        $this->layout = false;
        Yii::$app->response->format = \yii\web\Response::FORMAT_JSON;
        $apiKey = Yii::$app->request->headers->get('Authorization');
        if($this->getApikey( $apiKey )){
            $stoklar=Yii::$app->db->createCommand('SELECT StokKodu,fiyat4 as AdetFiyati,fiyat5 as KutuFiyati, Pm1, Pm2, Pm3,
            Barcode1, Barcode2, Barcode3, Vat, Barcode4,
               UrunAdi,Birim1,BirimKey1,Birim2,BirimKey2,Aktif,imsrc, qty as miktar
            FROM urunler WHERE aktif=1 and updated_at > :time and created_at<:time', ['time' => $this->convertToStandardDateTime($time)])->queryAll();
              foreach ($stoklar as &$stok) {
                $stok['AdetFiyati'] = (string) $stok['AdetFiyati'];
                $stok['KutuFiyati'] = (string) $stok['KutuFiyati'];
            }
            return [
                "status"=>1,
                "customers"=>$stoklar
        ];
        }
        else
            return [
                    "status"=>false,
                    "message"=>"invalid token"
            ];

    }

    public function actionIade()
    {
        $this->layout = false;
        Yii::$app->response->format = \yii\web\Response::FORMAT_JSON;

         // Get the raw JSON data
        $request = Yii::$app->request;
        $data = json_decode($request->getRawBody(), true);

        // Validate the data
        if (empty($data['fis']) || empty($data['satirlar'])) {
            return ['status' => 'error', 'message' => 'Geçersiz veri formatı'];
        }

        $transaction = Yii::$app->db->beginTransaction();
        try {
            // Save SatisFisleri
            $fis = new Iadefisleri();
            $fis->FisNo = $data['fis']['FisNo'];
            $fis->Fistarihi=date("Y-m-d");
            $fis->MusteriId=$data['fis']['MusteriId'];
            $fis->Toplamtutar=$data['fis']['Toplamtutar'];
            $fis->aciklama=$data['fis']['aciklama'];
            $fis->iadenedeni=$data['fis']['IadeNedeni'];
            if($data['fis']['aciklama'])
                $fis->aciklama=$data['fis']['aciklama'];
            if (!$fis->save()) {
                throw new \Exception("Fiş ".json_encode($fis->getErrors()));
            }
            // Save SatisSatirlar
            foreach ($data['satirlar'] as $satirData) {
                $satir = new Iadesatirlari();
               // $satir->attributes = $satirData;
                $satir->FisNo = $fis->FisNo; // Set the FisId from the saved fis
                $satir->StokKodu=$satirData['StokKodu'];
                $satir->Miktar=$satirData['Miktar'];
                $satir->BirimFiyat=$satirData['BirimFiyat'];
                $satir->ToplamTutar=$satirData['ToplamTutar'];
                $satir->BirimTipi=$satirData['BirimTipi'];
                $satir->UrunBarcode=$satirData['UrunBarcode'];
                $satir->tarih=date("Y-m-d H:i:s");
                $satir->aciklama=$satirData['aciklama'];
                if (!$satir->save()) {
                    throw new \Exception("Satir".json_encode($satir->getErrors()));
                }
            }

            $transaction->commit();
            Dia::fisgonder($fis,7);
            return [
                'IsSuccessStatusCode'=>true,
                'status' => 'success',
                'message' => 'Veri başarıyla kaydedildi',
                'fisNo' => $fis->FisNo
            ];



        } catch (\Exception $e) {
            $transaction->rollBack();
            return ['IsSuccessStatusCode'=>false,'status' => 'error', 'message' => $e->getMessage()];
        }
    }
    public function actionSatis()
    {
        $this->layout = false;
        Yii::$app->response->format = \yii\web\Response::FORMAT_JSON;
        $apiKey = Yii::$app->request->headers->get('Authorization');

        $jsonData = Yii::$app->request->getRawBody();
        $satisci = $this->getApikey($apiKey);

        $filePath = Yii::getAlias('@app/runtime/satis_log_' . date("Ymdhis") . '.txt');
        $logContent = "--- actionSatis LOG BAŞLANGIÇ ---\n";
        $logContent .= "Timestamp: " . date("Y-m-d H:i:s") . "\n";
        $logContent .= "API Key: " . $apiKey . "\n";
        $logContent .= "User: " . ($satisci ? $satisci : 'BULUNAMADI') . "\n\n";
        $logContent .= "Raw Data:\n";
        $logContent .= $jsonData . "\n\n";
        file_put_contents($filePath, $logContent);

        if (!$satisci) {
            file_put_contents($filePath, "HATA: Eksik veya Hatalı Apikey. İşlem sonlandırıldı.\n", FILE_APPEND);
            return ['IsSuccessStatusCode' => false, 'status' => 'error', 'message' => "Eksik veya Hatalı Apikey"];
        }

        $data = json_decode($jsonData, true);
        file_put_contents($filePath, "1. JSON Decode yapıldı.\n", FILE_APPEND);

        if (empty($data['fis']) || empty($data['satirlar'])) {
            file_put_contents($filePath, "HATA: Geçersiz veri formatı. 'fis' veya 'satirlar' anahtarları eksik. İşlem sonlandırıldı.\n", FILE_APPEND);
            return ['status' => 'error', 'message' => 'Geçersiz veri formatı'];
        }
        file_put_contents($filePath, "2. Veri formatı doğrulandı.\n", FILE_APPEND);

        // ✅ FisNo formatını kontrol et (MO + 14 rakam = 16 karakter)
        if (!isset($data['fis']['FisNo']) || !preg_match('/^MO\d{14}$/', $data['fis']['FisNo'])) {
            file_put_contents($filePath, "HATA: Geçersiz FisNo formatı. Beklenen: MO + 14 rakam (örn: MO25072405358823)\n", FILE_APPEND);
            file_put_contents($filePath, "Gelen FisNo: " . ($data['fis']['FisNo'] ?? 'BOŞ') . "\n", FILE_APPEND);
            return ['IsSuccessStatusCode' => false, 'status' => 'error', 'message' => 'Geçersiz sipariş numarası formatı'];
        }
        file_put_contents($filePath, "2.1. FisNo format kontrolü başarılı: {$data['fis']['FisNo']}\n", FILE_APPEND);

        // ✅ Duplicate FisNo kontrolü
        $existingFis = Satisfisleri::find()->where(['FisNo' => $data['fis']['FisNo']])->one();
        if ($existingFis) {
            file_put_contents($filePath, "HATA: Bu FisNo zaten mevcut: {$data['fis']['FisNo']}\n", FILE_APPEND);
            file_put_contents($filePath, "Mevcut Fiş Tarihi: {$existingFis->Fistarihi}, Müşteri: {$existingFis->MusteriId}\n", FILE_APPEND);
            return ['IsSuccessStatusCode' => false, 'status' => 'error', 'message' => 'Bu sipariş numarası daha önce kullanılmış'];
        }
        file_put_contents($filePath, "2.2. Duplicate FisNo kontrolü başarılı.\n", FILE_APPEND);

        $transaction = Yii::$app->db->beginTransaction();
        file_put_contents($filePath, "3. Veritabanı transaction başlatıldı.\n", FILE_APPEND);

        try {
            $fis = new Satisfisleri();
            $fis->attributes = $data['fis'];
            $fis->MusteriId=$data['fis']['MusteriId'];
            $fis->FisNo=$data['fis']['FisNo'];
            $fis->Fistarihi=date("Y-m-d");//$this->convertToStandardDateTime($data['fis']['Fistarihi']);
            $fis->deliverydate=$this->convertToStandardDateTime($data['fis']['DeliveryDate']." 00:00:00");
            $fis->Toplamtutar=$data['fis']['Toplamtutar'];
            $fis->satispersoneli=$satisci;
            $fis->comment=$data['fis']['Comment'];
            file_put_contents($filePath, "4. Satisfisleri modeli dolduruldu. Kaydediliyor...\nModel Data: " . json_encode($fis->attributes) . "\n", FILE_APPEND);

            if (!$fis->save()) {
                $errors = json_encode($fis->getErrors());
                file_put_contents($filePath, "HATA: Fiş kaydedilemedi. Hatalar: $errors\n", FILE_APPEND);
                throw new \Exception("Fiş kaydedilemedi: " . $errors);
            }
            file_put_contents($filePath, "5. Fiş başarıyla kaydedildi. FisNo: {$fis->FisNo}\n", FILE_APPEND);

            file_put_contents($filePath, "6. Satırları kaydetme işlemi başlıyor...\n", FILE_APPEND);
            foreach ($data['satirlar'] as $index => $satirData) {
                $satir = new Satissatirlari();
                $satir->attributes = $satirData;
                $satir->FisNo = $fis->FisNo; // Set the FisId from the saved fis
                $satir->satispersoneli=$satisci;
                $satir->BirimTipi=strtoupper($satirData["BirimTipi"]);
                file_put_contents($filePath, "   - Satır #$index modeli dolduruldu. Kaydediliyor...\nModel Data: " . json_encode($satir->attributes) . "\n", FILE_APPEND);
                if (!$satir->save()) {
                    $errors = json_encode($satir->getErrors());
                    file_put_contents($filePath, "HATA: Satır #$index kaydedilemedi. Hatalar: $errors\n", FILE_APPEND);
                    throw new \Exception("Satır kaydedilemedi: " . $errors);
                }
                file_put_contents($filePath, "   - Satır #$index başarıyla kaydedildi.\n", FILE_APPEND);
            }

            file_put_contents($filePath, "7. Transaction commit ediliyor...\n", FILE_APPEND);
            $transaction->commit();
            file_put_contents($filePath, "8. Transaction commit edildi.\n", FILE_APPEND);

            file_put_contents($filePath, "9. Dia::siparisgondermobil çağrılıyor...\n", FILE_APPEND);
             $sonuc = null;
            for ($say = 1; $say <= 3; $say++) {
                try {
                    $sonuc = Dia::siparisgondermobil($fis, 2, $filePath);
                    if ($sonuc == 1) break;
                } catch (\Throwable $e) {
                    // log vs.
                }
                usleep(300000);
            }

            file_put_contents($filePath, "10. Dia::siparisgondermobil çağrıldı.\n", FILE_APPEND);

            file_put_contents($filePath, "11. Başarılı yanıt dönülüyor.\n--- actionSatis LOG SON ---\n", FILE_APPEND);
            return [
                'IsSuccessStatusCode'=>true,
                'status' => 'success',
                'message' => 'Veri başarıyla kaydedildi',
                'fisNo' => $fis->FisNo
            ];
        } catch (\Exception $e) {
            file_put_contents($filePath, "\n!!! CATCH bloğuna girildi !!!\nTransaction rollback yapılıyor.\nHata Mesajı: " . $e->getMessage() . "\nSatır: " . $e->getLine() . "\nDosya: " . $e->getFile() . "\n--- actionSatis LOG SON ---\n", FILE_APPEND);
            $transaction->rollBack();
            return ['IsSuccessStatusCode'=>false,'status' => 'error', 'message' => $e->getMessage()];
        }
    }
    public function actionGetekstre($carikod,$tarih="2025-01-01",$detay=1){
        return Dia::getEkstre($carikod,$tarih,$detay);
    }
    public function actionMusterilistesi(){
        $this->layout = false;
        Yii::$app->response->format = \yii\web\Response::FORMAT_JSON;
        $apiKey = Yii::$app->request->headers->get('Authorization');

        $jsonData = Yii::$app->request->getRawBody();
        // $dataArray = json_decode($jsonData, true);
        $filePath = Yii::getAlias('@app/runtime/musteritalep'.date("Ymdhis").'.txt');

        $satisci=$this->getApikey( $apiKey );
        file_put_contents($filePath, $jsonData."APIKEY :".$apiKey." User :".$satisci);
        if(!$satisci)
            return  ['IsSuccessStatusCode'=>false,'status' => 'error', 'message' =>"Eksik veya Hatalı Apikey"];

        //$st=Satiscilar::find()->where(["kodu"=>$satisci])->one();
        $connection = Yii::$app->getDb();
        $command = $connection->createCommand("
            SELECT
                Unvan,VergiNo,VergiDairesi,Adres,Telefon,Email,Kod,postcode,city,contact,mobile, bakiye
            From musteriler Where Aktif=1 and satiselemani=:st
        ",[":st"=>$satisci]);
        $result = $command->queryAll();
        return $this->asJson($result);
    }
    public function actionMusteriurunleri($carikod){
        $connection = Yii::$app->getDb();
        $command = $connection->createCommand("
            SELECT
                sf.FisNo,
                sf.MusteriId,
                sf.FisTarihi,
                m.Unvan,
                ss.StokKodu,
                U.UrunAdi,
                ss.UrunBarcode,
                ss.Miktar,
                ss.Vat,
                ss.Iskonto,
                ss.BirimTipi as Birim,
                ss.BirimFiyat
             FROM SatisFisleri sf
                INNER JOIN Musteriler m ON m.Kod = sf.MusteriId
                INNER JOIN SatisSatirlari ss ON ss.FisNo = sf.FisNo
                left JOIN urunler U ON U.StokKodu = ss.StokKodu
                            WHERE m.kod = :carikod
                            ORDER BY sf.FisTarihi DESC
        ");

        $command->bindValue(':carikod', $carikod);
        $result = $command->queryAll();

        return $this->asJson($result);
    }

    public function actionNakittahsilat(){
        $this->layout = false;
        Yii::$app->response->format = \yii\web\Response::FORMAT_JSON;
        $apiKey = Yii::$app->request->headers->get('Authorization');
        $satisci=$this->getApikey( $apiKey );

        //if(!$satisci){

            if ($this->request->isPost) {
                $request = Yii::$app->request;
                $data = json_decode($request->getRawBody(), true);
                $hata=null;
                if($data["carikod"]!=null)
                {

                    $musteri=Musteriler::find()->where(["kod"=>$data["carikod"]])->one();
                    if($musteri!=null){
                        $model=new Carihareketler();
                        $model->FisId=$data["fisno"];
                        $model->Tutar=$data["tutar"];
                        $model->HareketTuru="Tahsilat";
                        $model->OdemeYontemi="Nakit";
                        $model->Aciklama=$data["aciklama"];
                        $model->CariId=strval($musteri->MusteriId);
                        $model->carikod=$musteri->Kod;
                        $model->IslemYapan="1";//;$satisci;

                        if($model->save())
                            Dia::tahsilatgonder($model);
                        else
                            return json_encode($model->getErrors());
                    }
                    else
                        return ["sonuc"=>false, "hata"=>"Müşteri bulunamadı"];
                }
            }
       // }
       // else
        //    return [ "status"=>false,"message"=>"invalid token" ];
    }
    public function actionKredikartitahsilat(){
        $this->layout = false;
        Yii::$app->response->format = \yii\web\Response::FORMAT_JSON;
        $apiKey = Yii::$app->request->headers->get('Authorization');
        $satisci=$this->getApikey( $apiKey );
       // if(!$satisci){
            if ($this->request->isPost) {
                $request = Yii::$app->request;
                $data = json_decode($request->getRawBody(), true);
                $hata=null;
                if($data["carikod"]!=null)
                {
                    $musteri=Musteriler::find()->where(["kod"=>$data["carikod"]])->one();

                    if($musteri!=null){
                        $model=new Carihareketler();
                        $model->FisId=$data["fisno"];
                        $model->Tutar=$data["tutar"];
                        $model->HareketTuru="Tahsilat";
                        $model->OdemeYontemi="Kredi Kartı";
                        $model->Aciklama=$data["aciklama"];
                        $model->CariId=strval($musteri->MusteriId);
                        $model->carikod=$musteri->Kod;
                        $model->IslemYapan=$satisci;
                        if($model->save())
                            Dia::tahsilatgonder($model);
                        else
                            $hata=json_encode($model->getErrors());
                    }
                }
            }
        // }
        // else
        //     return [
        //             "status"=>false,
        //             "message"=>"invalid token"
        //     ];
    }
    public function actionBankatahsilat(){
        $this->layout = false;
        Yii::$app->response->format = \yii\web\Response::FORMAT_JSON;
         $apiKey = Yii::$app->request->headers->get('Authorization');


        // $raw = Yii::$app->request->getRawBody();

        // $filePath = Yii::getAlias('@app/runtime/bankatahsilat'.date("Ymdhis").'.txt');
        // file_put_contents($filePath, json_encode($raw, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE));


         if($this->getApikey( $apiKey )){

             if ($this->request->isPost) {

                 $request = Yii::$app->request;
                 $data = json_decode($request->getRawBody(), true);

                $hata=null;
                if($data["carikod"]!=null)
                {

                    $musteri=Musteriler::find()->where(["kod"=>$data["carikod"]])->one();
                    if($musteri!=null){
                        $model=new Carihareketler();
                        $model->FisId=$data["fisno"];
                        $model->Tutar=$data["tutar"];
                        $model->HareketTuru="Tahsilat";
                        $model->OdemeYontemi="Çekle Tahsilat";
                        $model->Aciklama=$data["aciklama"];
                        $model->CariId=$musteri->MusteriId;
                        $model->carikod=$musteri->Kod;
                        $model->IslemYapan=1;//$data["username"];
                        if($model->save())
                            Dia::havalegonder($model);
                        else
                            return [$model->getErrors()];
                    }
                }
             }
         }
        else
            return [
                    "status"=>false,
                    "message"=>"invalid token"
            ];
    }
    public function actionCektahsilat(){
        $this->layout = false;
        Yii::$app->response->format = \yii\web\Response::FORMAT_JSON;
        $apiKey = Yii::$app->request->headers->get('Authorization');
        if($this->getApikey( $apiKey )){
            if ($this->request->isPost) {
               // ceknono, vade
                $request = Yii::$app->request;
                $data = json_decode($request->getRawBody(), true);
                $hata=null;
                if($data["carikod"]!=null)
                {
                    $musteri=Musteriler::find()->where(["kod"=>$data["carikod"]])->one();

                    if($musteri!=null){
                        $model=new Carihareketler();
                        $model->FisId=$data["fisno"];
                        $model->Tutar=$data["tutar"];
                        $model->HareketTuru="Tahsilat";
                        $model->OdemeYontemi="Çekle Tahsilat";
                        $model->Aciklama=$data["aciklama"];
                        $model->CariId=$musteri->MusteriId;
                        $model->carikod=$musteri->Kod;
                        $model->IslemYapan=$data["username"];
                        // if($model->save())
                        //     Dia::tahsilatgonder($model);
                        // else
                        //     $hata=json_encode($model->getErrors());
                    }
                }
            }
        }
        else
            return [
                    "status"=>false,
                    "message"=>"invalid token"
            ];
    }

    public function actionTedarikciler(){
        $connection = Yii::$app->getDb();
        $command = $connection->createCommand("
            SELECT * from tedarikci ORDER BY tedarikci_adi ASC
        ");

        $result = $command->queryAll();

        return $this->asJson($result);
    }

    public function actionIademusterileri(){
        $connection = Yii::$app->getDb();
        $command = $connection->createCommand("
            SELECT Distinct MusteriId from satisfisleri where fistarihi >= DATE_SUB(CURDATE(), INTERVAL 3 MONTH) order by MusteriId
        ");

        $result = $command->queryAll();

        return $this->asJson($result);
    }
}
