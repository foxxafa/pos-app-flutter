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
    use app\models\Birimler;
    use app\models\Barkodlar;
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
                    $action->id == 'kredikartitahsilat' ||
                    $action->id == 'musterilistesi' ||
                    $action->id == 'customercounts' ||
                    $action->id == 'productcounts' ||
                    $action->id == 'birimcounts' ||
                    $action->id == 'birimlerlistesi' ||
                    $action->id == 'getnewproducts' ||
                    $action->id == 'getupdatedproducts' ||
                    $action->id == 'getnewcustomer' ||
                    $action->id == 'getupdatedcustomer' ||
                    $action->id == 'getnewbirimler' ||
                    $action->id == 'getdepostok' ) {
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

            //return [$username,$password];
            $sp=Satiscilar::find()->where(["kodu"=>$username])->andWhere(['password'=>$password])->one();
            if ($sp) {
                // ✅ Depo kontrolü - Kullanıcının deposu yoksa giriş yapmasına izin verme
                if(!$sp->_key_sis_depo || $sp->_key_sis_depo == 0){
                    return [
                        'status' => 'error',
                        'message' => 'User is not assigned to any branch. Please contact your administrator.'
                    ];
                }

                // Basit API key üretimi (şimdilik sadece username döndür)
                $apiKey = $username; // Token sistemine geçene kadar username kullan

                return [
                    'status' => 'success',
                    'message' => 'Login successful',
                    'apikey' => $apiKey,
                    "prefix"=>"MBL"
                ];
            } else {
                return [
                    'status' => 'error',
                    'message' => 'Invalid username or password 01'
                ];
            }
        }



        private function getApikey($apiKey){
            // Token sistemine geçene kadar basitleştirildi - kontrol yok
            $apiKey = is_string($apiKey) ? $apiKey : '';
            if (str_starts_with($apiKey, 'Bearer ')) {
                $apiKey = trim(str_replace('Bearer', '', $apiKey));
            }

            // Direkt username döndür, kontrol etme (geçici çözüm)
            return !empty($apiKey) ? $apiKey : false;
        }

        public function actionGetnewcustomer(){
            $this->layout = false;
            Yii::$app->response->format = \yii\web\Response::FORMAT_JSON;
            $apiKey = Yii::$app->request->headers->get('Authorization');
            $satisci=$this->getApikey( $apiKey );

            $time = Yii::$app->request->get('time');
            if (!$time) {
                return [
                    'IsSuccessStatusCode' => false,
                    'status' => 'error',
                    'message' => 'time parametresi eksik'
                ];
            }

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

        public function actionGetupdatedcustomer(){
            $this->layout = false;
            Yii::$app->response->format = \yii\web\Response::FORMAT_JSON;
            $apiKey = Yii::$app->request->headers->get('Authorization');

            $time = Yii::$app->request->get('time');
            if (!$time) {
                return [
                    'IsSuccessStatusCode' => false,
                    'status' => 'error',
                    'message' => 'time parametresi eksik'
                ];
            }

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

        public function actionGetnewproducts(){
            $this->layout = false;
            Yii::$app->response->format = \yii\web\Response::FORMAT_JSON;
            $apiKey = Yii::$app->request->headers->get('Authorization');

            $time = Yii::$app->request->get('time');
            if (!$time) {
                return [
                    'IsSuccessStatusCode' => false,
                    'status' => 'error',
                    'message' => 'time parametresi eksik'
                ];
            }
            $user=$this->getApikey( $apiKey );
            if($user){
                // Pagination parametreleri
                $page = (int)Yii::$app->request->get('page', 1);
                $limit = (int)Yii::$app->request->get('limit', 5000);
                $offset = ($page - 1) * $limit;

                // ✅ Basit sorgu: Sadece urunler tablosunu çek
                // Depo stok bilgileri ayrı endpoint'ten (/getdepostok) alınacak
                $stoklar=Yii::$app->db->createCommand('SELECT StokKodu,fiyat4 as AdetFiyati,fiyat5 as KutuFiyati, Pm1, Pm2, Pm3,
                Barcode1, Barcode2, Barcode3, Vat, Barcode4,
                   UrunAdi,Birim1,BirimKey1,Birim2,BirimKey2,Aktif,imsrc, qty as miktar
                FROM urunler WHERE aktif=1 and created_at > :time
                ORDER BY StokKodu ASC
                LIMIT :limit OFFSET :offset', [
                    'time' => $this->convertToStandardDateTime($time),
                    ':limit' => $limit,
                    ':offset' => $offset
                ])->queryAll();

                foreach ($stoklar as &$stok) {
                    $stok['AdetFiyati'] = (string) $stok['AdetFiyati'];
                    $stok['KutuFiyati'] = (string) $stok['KutuFiyati'];
                }
                return [
                    "status"=>1,
                    "page"=>$page,
                    "limit"=>$limit,
                    "customers"=>$stoklar
                 ];
            }
            else
                return [
                        "status"=>false,
                        "message"=>"invalid token"
                ];

        }
        public function actionGetupdatedproducts(){
            $this->layout = false;
            Yii::$app->response->format = \yii\web\Response::FORMAT_JSON;
            $apiKey = Yii::$app->request->headers->get('Authorization');

            $time = Yii::$app->request->get('time');
            if (!$time) {
                return [
                    'IsSuccessStatusCode' => false,
                    'status' => 'error',
                    'message' => 'time parametresi eksik'
                ];
            }

            $user=$this->getApikey( $apiKey );
            if($user){
                // Pagination parametreleri
                $page = (int)Yii::$app->request->get('page', 1);
                $limit = (int)Yii::$app->request->get('limit', 5000);
                $offset = ($page - 1) * $limit;

                // ✅ Basit sorgu: Sadece urunler tablosunu çek
                // Depo stok bilgileri ayrı endpoint'ten (/getdepostok) alınacak
                $stoklar=Yii::$app->db->createCommand('SELECT StokKodu,fiyat4 as AdetFiyati,fiyat5 as KutuFiyati, Pm1, Pm2, Pm3,
                Barcode1, Barcode2, Barcode3, Vat, Barcode4,
                   UrunAdi,Birim1,BirimKey1,Birim2,BirimKey2,Aktif,imsrc, qty as miktar
                FROM urunler WHERE aktif=1 and updated_at > :time and created_at < :time
                ORDER BY StokKodu ASC
                LIMIT :limit OFFSET :offset', [
                    'time' => $this->convertToStandardDateTime($time),
                    ':limit' => $limit,
                    ':offset' => $offset
                ])->queryAll();

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

            // ✅ FisNo formatını kontrol et (MO + 13 rakam = 15 karakter)
            // Format: MO + YY + MM + DD + UserID + Minute + Microsecond
            // Example: MO251103010719286 (15 characters)
            /* if (!isset($data['fis']['FisNo']) || !preg_match('/^MO\d{13}$/', $data['fis']['FisNo'])) {
                return [
                    'IsSuccessStatusCode' => false,
                    'status' => 'error',
                    'message' => 'Geçersiz iade numarası formatı. Beklenen: MO + 13 rakam (örn: MO2511030107192)'
                ];
            } */

            // ✅ Duplicate FisNo kontrolü
            $existingFis = Iadefisleri::find()->where(['FisNo' => $data['fis']['FisNo']])->one();
            if ($existingFis) {
                return [
                    'IsSuccessStatusCode' => false,
                    'status' => 'error',
                    'message' => 'Bu iade numarası daha önce kullanılmış'
                ];
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

                // ✅ Return response first, then send to DIA (to avoid JSON corruption)
                $response = [
                    'IsSuccessStatusCode'=>true,
                    'status' => 'success',
                    'message' => 'Veri başarıyla kaydedildi',
                    'fisNo' => $fis->FisNo
                ];

                // Send to DIA after response is prepared (non-blocking)
                try {
                    Dia::fisgonder($fis,7);
                } catch (\Exception $e) {
                    // Log error but don't fail the response
                    Yii::error("DIA gönderim hatası (Refund {$fis->FisNo}): " . $e->getMessage());
                }

                return $response;



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

            // ✅ FisNo formatını kontrol et (MO + 13 rakam = 15 karakter)
            // Format: MO + YY + MM + DD + UserID + Minute + Microsecond
            // Example: MO251103010719286 (15 characters)
            /* if (!isset($data['fis']['FisNo']) || !preg_match('/^MO\d{13}$/', $data['fis']['FisNo'])) {
                file_put_contents($filePath, "HATA: Geçersiz FisNo formatı. Beklenen: MO + 13 rakam (örn: MO2511030107192)\n", FILE_APPEND);
                file_put_contents($filePath, "Gelen FisNo: " . ($data['fis']['FisNo'] ?? 'BOŞ') . "\n", FILE_APPEND);
                return ['IsSuccessStatusCode' => false, 'status' => 'error', 'message' => 'Geçersiz sipariş numarası formatı'];
            } */
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
        public function actionGetekstre($carikod,$tarih="2025-01-01",$detay=1,$tarih2=null,$ft=0){
            if($tarih2==null)
                $trih2=date("Y-m-d H:i:s");

            return Dia::getEkstre($carikod,$tarih,$detay,$tarih2,$ft);
        }
        public function actionMusterilistesi(){
            $this->layout = false;
            Yii::$app->response->format = \yii\web\Response::FORMAT_JSON;
            $apiKey = Yii::$app->request->headers->get('Authorization');

            // Debug log
            \Yii::error("musterilistesi called with apiKey: " . $apiKey, 'api');

            $satisci = $this->getApikey($apiKey);

            // Debug log
            \Yii::error("getApikey returned: " . ($satisci ? $satisci : 'false'), 'api');

            if(!$satisci)
                return ['IsSuccessStatusCode'=>false, 'status' => 'error', 'message' =>"Eksik veya Hatalı Apikey"];

            // Pagination parametreleri
            $page = (int)Yii::$app->request->get('page', 1);
            $limit = (int)Yii::$app->request->get('limit', 5000);
            $offset = ($page - 1) * $limit;

            try {
                $connection = Yii::$app->getDb();
                $command = $connection->createCommand("
                    SELECT
                        Unvan,VergiNo,VergiDairesi,Adres,Telefon,Email,Kod,postcode,city,contact,mobile, bakiye
                    From musteriler Where Aktif=1 and satiselemani=:st
                    ORDER BY MusteriId ASC
                    LIMIT :limit OFFSET :offset
                ",[
                    ":st"=>$satisci,
                    ":limit"=>$limit,
                    ":offset"=>$offset
                ]);
                $result = $command->queryAll();

                return [
                    'status' => 1,
                    'page' => $page,
                    'limit' => $limit,
                    'customers' => $result
                ];
            } catch (\Exception $e) {
                return [
                    'IsSuccessStatusCode' => false,
                    'status' => 'error',
                    'message' => 'Veri alınamadı: ' . $e->getMessage()
                ];
            }
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
                            $model->status=0;
                            $model->IslemYapan="1";//;$satisci;

                            if($model->save()){
                                //Dia::tahsilatgonder($model);
                            }
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
                            $model->HareketTarihi=date("Y-m-d");
                            $model->status=1;

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
                            $model->HareketTarihi=date("Y-m-d");
                            $model->OdemeYontemi="Çekle Tahsilat";
                            $model->Aciklama=$data["aciklama"];
                            $model->CariId=$musteri->MusteriId;
                            $model->carikod=$musteri->Kod;
                            $model->IslemYapan=1;//$data["username"];
                            $model->status=1;

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
            $logMessage = "======= ÇEKLE TAHSİLAT ======";

            //if($this->getApikey( $apiKey )){
                $logMessage .="Apikey :".$apiKey."\n";
                //if ($this->request->isPost) {
                   // ceknono, vade
                    $request = Yii::$app->request;
                    $rawBody = $request->getRawBody();
                    $rawFilePath = \Yii::getAlias('@runtime/cektahsilat_raw_'.date("Ymd_His").'_'.uniqid().'.txt');
                    file_put_contents($rawFilePath, $rawBody, LOCK_EX);
                    $data = json_decode($rawBody, true);
                    $logMessage .=$rawBody."\n";
                    $hata=null;
                    file_put_contents(\Yii::getAlias('@runtime/dia_tahsilat_log00_'.date("Ymd_His").'.txt'), $logMessage, FILE_APPEND | LOCK_EX);

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
                            $model->CariId=strval($musteri->MusteriId);
                            $model->carikod=$musteri->Kod;
                            $model->IslemYapan=$data["username"];
                            $model->cek_no=$data["cekno"] ?? null;
                            $model->vadetarihi=$data["vade"] ?? null;
                            $model->status=0;

                            if($model->save()){
                            $logMessage .="Kayıt işlemi başarıl \n";
                            //Dia::tahsilatgonder($model);
                            }

                            else{
                            $hata=json_encode($model->getErrors());
                            $logMessage .="Kayıt işlemi başarısız :".$hata." \n";
                            }

                        }
                    }
                    file_put_contents(\Yii::getAlias('@runtime/dia_tahsilat_log00_'.date("Ymd_His").'.txt'), $logMessage, FILE_APPEND | LOCK_EX);

                    return true;
                //}
            ;/*}
            else
                return [
                        "status"=>false,
                        "message"=>"invalid token"
                ];
                */
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

        /**
         * Birim ve barkod sayılarını döner
         * GET: /apimobil/birimcounts
         */
        public function actionBirimcounts(){
            $this->layout = false;
            Yii::$app->response->format = \yii\web\Response::FORMAT_JSON;
            $apiKey = Yii::$app->request->headers->get('Authorization');

            if(!$this->getApikey($apiKey))
                return ['IsSuccessStatusCode'=>false, 'status' => 'error', 'message' =>"Eksik veya Hatalı Apikey"];

            try {
                $connection = Yii::$app->getDb();

                // Birim sayısını al
                $birimCount = $connection->createCommand("SELECT COUNT(*) as count FROM birimler")->queryScalar();

                // Barkod sayısını al
                $barkodCount = $connection->createCommand("SELECT COUNT(*) as count FROM barkodlar")->queryScalar();

                return [
                    'status' => 1,
                    'birimler_count' => (int)$birimCount,
                    'barkodlar_count' => (int)$barkodCount
                ];

            } catch (\Exception $e) {
                return [
                    'IsSuccessStatusCode' => false,
                    'status' => 'error',
                    'message' => 'Veri alınamadı: ' . $e->getMessage()
                ];
            }
        }

        /**
         * Product kayıt sayısını döner
         * GET: /apimobil/productcounts
         */
        public function actionProductcounts(){
            $this->layout = false;
            Yii::$app->response->format = \yii\web\Response::FORMAT_JSON;
            $apiKey = Yii::$app->request->headers->get('Authorization');

            if(!$this->getApikey($apiKey))
                return ['IsSuccessStatusCode'=>false, 'status' => 'error', 'message' =>"Eksik veya Hatalı Apikey"];

            try {
                $connection = Yii::$app->getDb();

                // Aktif ürün sayısını al
                $productCount = $connection->createCommand("SELECT COUNT(*) as count FROM urunler WHERE aktif=1")->queryScalar();

                return [
                    'status' => 1,
                    'product_count' => (int)$productCount
                ];
            } catch (\Exception $e) {
                return [
                    'IsSuccessStatusCode' => false,
                    'status' => 'error',
                    'message' => 'Veri alınamadı: ' . $e->getMessage()
                ];
            }
        }

        /**
         * Customer kayıt sayısını döner
         * GET: /apimobil/customercounts
         */
        public function actionCustomercounts(){
            $this->layout = false;
            Yii::$app->response->format = \yii\web\Response::FORMAT_JSON;
            $apiKey = Yii::$app->request->headers->get('Authorization');

            $satisci = $this->getApikey($apiKey);
            if(!$satisci)
                return ['IsSuccessStatusCode'=>false, 'status' => 'error', 'message' =>"Eksik veya Hatalı Apikey"];

            try {
                $connection = Yii::$app->getDb();

                // Satış elemanına ait aktif müşteri sayısını al
                $customerCount = $connection->createCommand(
                    "SELECT COUNT(*) as count FROM musteriler WHERE Aktif=1 AND satiselemani=:st",
                    [":st" => $satisci]
                )->queryScalar();

                return [
                    'status' => 1,
                    'customer_count' => (int)$customerCount
                ];
            } catch (\Exception $e) {
                return [
                    'IsSuccessStatusCode' => false,
                    'status' => 'error',
                    'message' => 'Veri alınamadı: ' . $e->getMessage()
                ];
            }
        }

        /**
         * Birimleri ve barkodları sayfalı şekilde döner
         * GET: /apimobil/birimlerlistesi?page=1&limit=5000
         */
        public function actionBirimlerlistesi(){
            $this->layout = false;
            Yii::$app->response->format = \yii\web\Response::FORMAT_JSON;
            $apiKey = Yii::$app->request->headers->get('Authorization');

            if(!$this->getApikey($apiKey))
                return ['IsSuccessStatusCode'=>false, 'status' => 'error', 'message' =>"Eksik veya Hatalı Apikey"];

            // Pagination parametreleri
            $page = (int)Yii::$app->request->get('page', 1);
            $limit = (int)Yii::$app->request->get('limit', 5000);
            $offset = ($page - 1) * $limit;

            try {
                $connection = Yii::$app->getDb();

                // Birimleri çek
                $birimlerCommand = $connection->createCommand("
                    SELECT
                        id,
                        birimadi,
                        birimkod,
                        carpan,
                        fiyat1,
                        fiyat2,
                        fiyat3,
                        fiyat4,
                        fiyat5,
                        fiyat6,
                        fiyat7,
                        fiyat8,
                        fiyat9,
                        fiyat10,
                        _key,
                        _key_scf_stokkart,
                        StokKodu,
                        created_at,
                        updated_at
                    FROM birimler
                    ORDER BY id ASC
                    LIMIT :limit OFFSET :offset
                ", [':limit' => $limit, ':offset' => $offset]);
                $birimler = $birimlerCommand->queryAll();

                // Barkodları çek
                $barkodlarCommand = $connection->createCommand("
                    SELECT
                        id,
                        _key,
                        _key_scf_stokkart_birimleri,
                        barkod,
                        turu,
                        created_at,
                        updated_at
                    FROM barkodlar
                    ORDER BY id ASC
                    LIMIT :limit OFFSET :offset
                ", [':limit' => $limit, ':offset' => $offset]);
                $barkodlar = $barkodlarCommand->queryAll();

                return [
                    'status' => 1,
                    'page' => $page,
                    'limit' => $limit,
                    'birimler' => $birimler,
                    'barkodlar' => $barkodlar
                ];

            } catch (\Exception $e) {
                return [
                    'IsSuccessStatusCode' => false,
                    'status' => 'error',
                    'message' => 'Veri alınamadı: ' . $e->getMessage(),
                    'trace' => $e->getTraceAsString()
                ];
            }
        }

        /**
         * Belirli bir tarihten sonra oluşturulan/güncellenen birimleri döner
         * GET: /apimobil/getnewbirimler?time=01.05.2024 15:55:30
         *
         * Query Parameters:
         *  - time: Tarih formatı "dd.MM.yyyy HH:mm:ss"
         */
        public function actionGetnewbirimler(){
            $this->layout = false;
            Yii::$app->response->format = \yii\web\Response::FORMAT_JSON;
            $apiKey = Yii::$app->request->headers->get('Authorization');

            if(!$this->getApikey($apiKey))
                return ['IsSuccessStatusCode'=>false, 'status' => 'error', 'message' =>"Eksik veya Hatalı Apikey"];

            $time = Yii::$app->request->get('time');
            if (!$time) {
                return [
                    'IsSuccessStatusCode' => false,
                    'status' => 'error',
                    'message' => 'time parametresi eksik'
                ];
            }

            $dateString = str_replace('%20', ' ', $time);
            $date = \DateTime::createFromFormat('d.m.Y H:i:s', $dateString);

            if ($date) {
                $tarih = $date->format('Y-m-d H:i:s');
            } else {
                return [
                    "status" => 0,
                    "hata" => "Geçersiz tarih ve zaman formatı"
                ];
            }

            try {
                $connection = Yii::$app->getDb();

                // Yeni birimleri çek
                $birimlerCommand = $connection->createCommand("
                    SELECT
                        id,
                        birimadi,
                        birimkod,
                        carpan,
                        fiyat1,
                        fiyat2,
                        fiyat3,
                        fiyat4,
                        fiyat5,
                        fiyat6,
                        fiyat7,
                        fiyat8,
                        fiyat9,
                        fiyat10,
                        _key,
                        _key_scf_stokkart,
                        StokKodu,
                        created_at,
                        updated_at
                    FROM birimler
                    WHERE created_at > :time OR updated_at > :time
                    ORDER BY id ASC
                ", [':time' => $tarih]);
                $birimler = $birimlerCommand->queryAll();

                // Yeni barkodları çek
                $barkodlarCommand = $connection->createCommand("
                    SELECT
                        id,
                        _key,
                        _key_scf_stokkart_birimleri,
                        barkod,
                        turu,
                        created_at,
                        updated_at
                    FROM barkodlar
                    WHERE created_at > :time OR updated_at > :time
                    ORDER BY id ASC
                ", [':time' => $tarih]);
                $barkodlar = $barkodlarCommand->queryAll();

                return [
                    'status' => 1,
                    'birimler' => $birimler,
                    'barkodlar' => $barkodlar
                ];

            } catch (\Exception $e) {
                return [
                    'IsSuccessStatusCode' => false,
                    'status' => 'error',
                    'message' => 'Veri alınamadı: ' . $e->getMessage()
                ];
            }
        }

        /**
         * Kullanıcının deposundaki stok bilgilerini çeker
         * GET /apimobil/getdepostok
         */
        public function actionGetdepostok(){
            $this->layout = false;
            Yii::$app->response->format = \yii\web\Response::FORMAT_JSON;
            $apiKey = Yii::$app->request->headers->get('Authorization');

            $user = $this->getApikey($apiKey);
            if(!$user){
                return [
                    'IsSuccessStatusCode' => false,
                    'status' => 'error',
                    'message' => 'Geçersiz API key'
                ];
            }

            // Kullanıcının deposunu bul
            $depo = Satiscilar::find()->where(["kodu" => $user])->one();

            // ✅ Depo yoksa veya 0 ise boş liste dön (qty kullanılmaya devam edilsin)
            if(!$depo || !$depo->_key_sis_depo || $depo->_key_sis_depo == 0){
                return [
                    'status' => 0,
                    'page' => 1,
                    'limit' => 5000,
                    'depot_key' => null,
                    'depostok' => [],
                    'message' => 'User is not assigned to any branch'
                ];
            }

            $depokodu = $depo->_key_sis_depo;

            // Pagination parametreleri
            $page = (int)Yii::$app->request->get('page', 1);
            $limit = (int)Yii::$app->request->get('limit', 5000);
            $offset = ($page - 1) * $limit;

            try {
                // Sadece bu depodaki stokları çek (birim ile birlikte)
                $stoklar = Yii::$app->db->createCommand('
                    SELECT
                        StokKodu,
                        birim,
                        miktar
                    FROM depostok
                    WHERE warehouse_key = :depokodu
                    ORDER BY StokKodu ASC, birim ASC
                    LIMIT :limit OFFSET :offset
                ', [
                    ':depokodu' => $depokodu,
                    ':limit' => $limit,
                    ':offset' => $offset
                ])->queryAll();

                // miktar'ı double'a çevir
                foreach ($stoklar as &$stok) {
                    $stok['miktar'] = (double)$stok['miktar'];
                }

                return [
                    'status' => 1,
                    'page' => $page,
                    'limit' => $limit,
                    'depot_key' => $depokodu,
                    'depostok' => $stoklar
                ];

            } catch (\Exception $e) {
                return [
                    'IsSuccessStatusCode' => false,
                    'status' => 'error',
                    'message' => 'Depo stok bilgileri alınamadı: ' . $e->getMessage()
                ];
            }
        }
    }
