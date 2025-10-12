<?php

namespace app\models;

use Yii;
use yii\behaviors\TimestampBehavior;
use yii\db\Expression;
use app\models\Siparisler;
use app\models\SatinAlmaSiparisFis;
use app\models\SatinAlmaSiparisFisSatir;
use app\models\Tedarikci;

/**
 * This is the model class for table "siparis_ayrintili".
 *
 * @property int $id
 * @property string|null $__dinamik__1
 * @property string|null $__format
 * @property string|null $_cdate
 * @property string|null $_date
 * @property string|null $_key
 * @property string|null $_key_kalemturu
 * @property string|null $_key_scf_carikart
 * @property string|null $_key_scf_siparis
 * @property string|null $_key_scf_siparis_alinan
 * @property string|null $_key_scf_stokkart_tedarikci
 * @property string|null $_key_sis_depo_source
 * @property string|null $_key_sis_doviz
 * @property string|null $_key_sis_kullanici_onaylayan
 * @property int|null $_owner
 * @property int|null $_printcount
 * @property int|null $_serial
 * @property int|null $_user
 * @property string|null $aciklama
 * @property string|null $anabarkod
 * @property string|null $anabirimi
 * @property float|null $anamiktar
 * @property float|null $bekleyenmiktar
 * @property float|null $bekleyenmiktarhesaplanan
 * @property string|null $belgeno
 * @property float|null $birimfiyati
 * @property string|null $birimfiyatidovizi
 * @property string|null $__carikodu
 * @property string|null $depo
 * @property string|null $ekleyenkullaniciadi
 * @property string|null $fisno
 * @property string|null $gorusmenotu
 * @property string|null $kalemturu
 * @property string|null $kartaciklama
 * @property string|null $kartekalan1
 * @property string|null $kartekalan10
 * @property string|null $kartekalan2
 * @property string|null $kartekalan3
 * @property string|null $kartekalan4
 * @property string|null $kartekalan5
 * @property string|null $kartekalan6
 * @property string|null $kartekalan7
 * @property string|null $kartekalan8
 * @property string|null $kartekalan9
 * @property string|null $kartkodu
 * @property string|null $kartozelkodu1
 * @property string|null $kartozelkodu10
 * @property string|null $kartozelkodu11
 * @property string|null $kartozelkodu2
 * @property string|null $kartozelkodu2aciklama
 * @property string|null $kartozelkodu3
 * @property string|null $kartozelkodu4
 * @property string|null $kartozelkodu5
 * @property string|null $kartozelkodu6
 * @property string|null $kartozelkodu7
 * @property string|null $kartozelkodu8
 * @property string|null $kartozelkodu9
 * @property float|null $kdv
 * @property float|null $kdvalis
 * @property float|null $kdvsatis
 * @property float|null $kdvsatistoptan
 * @property string|null $kdvtevkifatkodu
 * @property float|null $kdvtevkifatorani
 * @property float|null $kdvtevkifattutari
 * @property float|null $kdvtutari
 * @property float|null $kdvtutarisatirdovizi
 * @property string|null $kullaniciadi
 * @property float|null $miktar
 * @property float|null $miktar_rezerv
 * @property string|null $onay
 * @property string|null $onay_siparis
 * @property string|null $onay_txt
 * @property string|null $onaylanmatarihi
 * @property string|null $onaylayan
 * @property string|null $siparisdurum
 * @property string|null $siparisikincibirimi
 * @property float|null $siparisikincibirimmiktar
 * @property int|null $sipariskalemkey
 * @property string|null $sipbirimi
 * @property int|null $sipbirimkey
 * @property string|null $siptarih
 * @property int|null $sirano
 * @property float|null $sonbirimfiyati
 * @property float|null $sonbirimfiyatifisdovizi
 * @property float|null $sontutaryerel
 * @property int|null $stokanabirimkey
 * @property string|null $sube
 * @property string|null $tarih
 * @property float|null $teslimatmiktar
 * @property string|null $teslimattarihi
 * @property float|null $teslimedilmeyenmiktar
 * @property float|null $toplambrutagirlik
 * @property float|null $toplambruthacim
 * @property float|null $toplamnetagirlik
 * @property float|null $toplamnethacim
 * @property float|null $toplamtutar
 * @property float|null $toplamtutarsatirdovizi
 * @property string|null $turu
 * @property string|null $turuack
 * @property float|null $tutari
 * @property float|null $tutarisatirdovizi
 * @property float|null $yerelbirimfiyati
 * @property int|null $siparisler_id
 * @property string $created_at
 * @property string $updated_at
 * @property string|null $tedarikci_key
 */
class SiparislerAyrintili extends \yii\db\ActiveRecord
{


    /**
     * {@inheritdoc}
     */
    public function behaviors()
    {
        return [
            [
                'class' => TimestampBehavior::class,
                'createdAtAttribute' => 'created_at',
                'updatedAtAttribute' => 'updated_at',
                'value' => new Expression('NOW()'),
            ],
        ];
    }
    
    /**
     * {@inheritdoc}
     */
    public static function tableName()
    {
        return 'siparis_ayrintili';
    }

    /**
     * {@inheritdoc}
     */
    public function rules()
    {
        return [
            [['__dinamik__1', '__format', '_cdate', '_date', '_key', '_key_kalemturu',
                '_key_scf_carikart', '_key_scf_siparis', '_key_scf_siparis_alinan',
                '_key_scf_stokkart_tedarikci', '_key_sis_depo_source', '_key_sis_doviz',
                '_key_sis_kullanici_onaylayan', '_owner', '_printcount', '_serial', '_user',
                'aciklama', 'anabarkod', 'anabirimi', 'anamiktar', 'bekleyenmiktar',
                'bekleyenmiktarhesaplanan', 'belgeno', 'birimfiyati', 'birimfiyatidovizi',
                '__carikodu', 'depo', 'ekleyenkullaniciadi', 'fisno', 'gorusmenotu',
                'kalemturu', 'kartaciklama', 'kartekalan1', 'kartekalan10', 'kartekalan2',
                'kartekalan3', 'kartekalan4', 'kartekalan5', 'kartekalan6', 'kartekalan7',
                'kartekalan8', 'kartekalan9', 'kartkodu', 'kartozelkodu1', 'kartozelkodu10',
                'kartozelkodu11', 'kartozelkodu2', 'kartozelkodu2aciklama', 'kartozelkodu3',
                'kartozelkodu4', 'kartozelkodu5', 'kartozelkodu6', 'kartozelkodu7',
                'kartozelkodu8', 'kartozelkodu9', 'kdv', 'kdvalis', 'kdvsatis',
                'kdvsatistoptan', 'kdvtevkifatkodu', 'kdvtevkifatorani', 'kdvtevkifattutari',
                'kdvtutari', 'kdvtutarisatirdovizi', 'kullaniciadi', 'miktar', 'miktar_rezerv',
                'onay', 'onay_siparis', 'onay_txt', 'onaylanmatarihi', 'onaylayan',
                'siparisdurum', 'siparisikincibirimi', 'siparisikincibirimmiktar',
                'sipariskalemkey', 'sipbirimi', 'sipbirimkey', 'siptarih', 'sirano',
                'sonbirimfiyati', 'sonbirimfiyatifisdovizi', 'sontutaryerel', 'stokanabirimkey',
                'sube', 'tarih', 'teslimatmiktar', 'teslimattarihi', 'teslimedilmeyenmiktar',
                'toplambrutagirlik', 'toplambruthacim', 'toplamnetagirlik', 'toplamnethacim',
                'toplamtutar', 'toplamtutarsatirdovizi', 'turu', 'turuack', 'tutari',
                'tutarisatirdovizi', 'yerelbirimfiyati', 'siparisler_id', 'tedarikci_key'], 'default', 'value' => null],
            
            [['id', '_owner', '_printcount', '_serial', '_user', 'sipariskalemkey',
                'sipbirimkey', 'sirano', 'stokanabirimkey', 'siparisler_id'], 'integer'],
            [['_cdate', '_date', 'onaylanmatarihi', 'siptarih', 'tarih', 'created_at', 'updated_at'], 'safe'],
            [['anamiktar', 'bekleyenmiktar', 'bekleyenmiktarhesaplanan', 'birimfiyati',
                'kdv', 'kdvalis', 'kdvsatis', 'kdvsatistoptan', 'kdvtevkifatorani',
                'kdvtevkifattutari', 'kdvtutari', 'kdvtutarisatirdovizi', 'miktar',
                'miktar_rezerv', 'siparisikincibirimmiktar', 'sonbirimfiyati',
                'sonbirimfiyatifisdovizi', 'sontutaryerel', 'teslimatmiktar',
                'teslimedilmeyenmiktar', 'toplambrutagirlik', 'toplambruthacim',
                'toplamnetagirlik', 'toplamnethacim', 'toplamtutar', 'toplamtutarsatirdovizi',
                'tutari', 'tutarisatirdovizi', 'yerelbirimfiyati', 'kdvtutarisatirdovizi'], 'number'],
            [['__dinamik__1', 'belgeno', 'depo', 'ekleyenkullaniciadi', 'kartekalan2', 'kartekalan5', 'kartekalan6',
                'kartekalan8', 'kartozelkodu2', 'kartozelkodu2aciklama', 'kartozelkodu3',
                'kartozelkodu6', 'kartozelkodu7', 'kdvtevkifatkodu', 'kullaniciadi',
                'onay_txt', 'onaylayan', 'siparisdurum', 'sube', 'turuack', 'anabarkod', 'tedarikci_key'], 'string', 'max' => 50],
            [['_key', '_key_kalemturu', '_key_scf_carikart', '_key_scf_siparis',
                '_key_scf_siparis_alinan', '_key_scf_stokkart_tedarikci', '_key_sis_depo_source',
                '_key_sis_doviz', '_key_sis_kullanici_onaylayan'], 'string', 'max' => 30],
            [['__format', 'anabirimi', '__carikodu', 'fisno', 'kartekalan1', 'kartekalan3',
                'kartekalan4', 'kartekalan7', 'kartkodu', 'kartozelkodu1', 'kartozelkodu4',
                'kartozelkodu5', 'onay', 'onay_siparis', 'siparisikincibirimi', 'sipbirimi',
                'teslimattarihi'], 'string', 'max' => 20],
            [['aciklama', 'kartaciklama', 'kartekalan10', 'kartekalan9', 'kartozelkodu10',
                'kartozelkodu11', 'kartozelkodu8', 'kartozelkodu9'], 'string', 'max' => 100],
            [['gorusmenotu'], 'string', 'max' => 255],
            [['birimfiyatidovizi', 'kalemturu', 'turu'], 'string', 'max' => 10],
            [['id'], 'unique'],
        ];
    }

    /**
     * {@inheritdoc}
     */
    public function attributeLabels()
    {
        return [
            'id' => 'ID',
            '__dinamik__1' => 'Dinamik  1',
            '__format' => 'Format',
            '_cdate' => 'Cdate',
            '_date' => 'Date',
            '_key' => 'Key',
            '_key_kalemturu' => 'Key Kalemturu',
            '_key_scf_carikart' => 'Key Scf Carikart',
            '_key_scf_siparis' => 'Key Scf Siparis',
            '_key_scf_siparis_alinan' => 'Key Scf Siparis Alinan',
            '_key_scf_stokkart_tedarikci' => 'Key Scf Stokkart Tedarikci',
            '_key_sis_depo_source' => 'Key Sis Depo Source',
            '_key_sis_doviz' => 'Key Sis Doviz',
            '_key_sis_kullanici_onaylayan' => 'Key Sis Kullanici Onaylayan',
            '_owner' => 'Owner',
            '_printcount' => 'Printcount',
            '_serial' => 'Serial',
            '_user' => 'User',
            'aciklama' => 'Aciklama',
            'anabarkod' => 'Anabarkod',
            'anabirimi' => 'Anabirimi',
            'anamiktar' => 'Anamiktar',
            'bekleyenmiktar' => 'Bekleyenmiktar',
            'bekleyenmiktarhesaplanan' => 'Bekleyenmiktarhesaplanan',
            'belgeno' => 'Belgeno',
            'birimfiyati' => 'Birimfiyati',
            'birimfiyatidovizi' => 'Birimfiyatidovizi',
            '__carikodu' => 'Carikodu',
            'depo' => 'Depo',
            'ekleyenkullaniciadi' => 'Ekleyenkullaniciadi',
            'fisno' => 'Fisno',
            'gorusmenotu' => 'Gorusmenotu',
            'kalemturu' => 'Kalemturu',
            'kartaciklama' => 'Kartaciklama',
            'kartekalan1' => 'Kartekalan1',
            'kartekalan10' => 'Kartekalan10',
            'kartekalan2' => 'Kartekalan2',
            'kartekalan3' => 'Kartekalan3',
            'kartekalan4' => 'Kartekalan4',
            'kartekalan5' => 'Kartekalan5',
            'kartekalan6' => 'Kartekalan6',
            'kartekalan7' => 'Kartekalan7',
            'kartekalan8' => 'Kartekalan8',
            'kartekalan9' => 'Kartekalan9',
            'kartkodu' => 'Kartkodu',
            'kartozelkodu1' => 'Kartozelkodu1',
            'kartozelkodu10' => 'Kartozelkodu10',
            'kartozelkodu11' => 'Kartozelkodu11',
            'kartozelkodu2' => 'Kartozelkodu2',
            'kartozelkodu2aciklama' => 'Kartozelkodu2aciklama',
            'kartozelkodu3' => 'Kartozelkodu3',
            'kartozelkodu4' => 'Kartozelkodu4',
            'kartozelkodu5' => 'Kartozelkodu5',
            'kartozelkodu6' => 'Kartozelkodu6',
            'kartozelkodu7' => 'Kartozelkodu7',
            'kartozelkodu8' => 'Kartozelkodu8',
            'kartozelkodu9' => 'Kartozelkodu9',
            'kdv' => 'Kdv',
            'kdvalis' => 'Kdvalis',
            'kdvsatis' => 'Kdvsatis',
            'kdvsatistoptan' => 'Kdvsatistoptan',
            'kdvtevkifatkodu' => 'Kdvtevkifatkodu',
            'kdvtevkifatorani' => 'Kdvtevkifatorani',
            'kdvtevkifattutari' => 'Kdvtevkifattutari',
            'kdvtutari' => 'Kdvtutari',
            'kdvtutarisatirdovizi' => 'Kdvtutarisatirdovizi',
            'kullaniciadi' => 'Kullaniciadi',
            'miktar' => 'Miktar',
            'miktar_rezerv' => 'Miktar Rezerv',
            'onay' => 'Onay',
            'onay_siparis' => 'Onay Siparis',
            'onay_txt' => 'Onay Txt',
            'onaylanmatarihi' => 'Onaylanmatarihi',
            'onaylayan' => 'Onaylayan',
            'siparisdurum' => 'Siparisdurum',
            'siparisikincibirimi' => 'Siparisikincibirimi',
            'siparisikincibirimmiktar' => 'Siparisikincibirimmiktar',
            'sipariskalemkey' => 'Sipariskalemkey',
            'sipbirimi' => 'Sipbirimi',
            'sipbirimkey' => 'Sipbirimkey',
            'siptarih' => 'Siptarih',
            'sirano' => 'Sirano',
            'sonbirimfiyati' => 'Sonbirimfiyati',
            'sonbirimfiyatifisdovizi' => 'Sonbirimfiyatifisdovizi',
            'sontutaryerel' => 'Sontutaryerel',
            'stokanabirimkey' => 'Stokanabirimkey',
            'sube' => 'Sube',
            'tarih' => 'Tarih',
            'teslimatmiktar' => 'Teslimatmiktar',
            'teslimattarihi' => 'Teslimattarihi',
            'teslimedilmeyenmiktar' => 'Teslimedilmeyenmiktar',
            'toplambrutagirlik' => 'Toplambrutagirlik',
            'toplambruthacim' => 'Toplambruthacim',
            'toplamnetagirlik' => 'Toplamnetagirlik',
            'toplamnethacim' => 'Toplamnethacim',
            'toplamtutar' => 'Toplamtutar',
            'toplamtutarsatirdovizi' => 'Toplamtutarsatirdovizi',
            'turu' => 'Turu',
            'turuack' => 'Turuack',
            'tutari' => 'Tutari',
            'tutarisatirdovizi' => 'Tutarisatirdovizi',
            'yerelbirimfiyati' => 'Yerelbirimfiyati',
            'siparisler_id' => 'Siparisler ID',
            'created_at' => 'Created At',
            'updated_at' => 'Updated At',
            'tedarikci_key' => 'Tedarikci Key',
        ];
    }

    public function beforeSave($insert)
    {
        if (parent::beforeSave($insert)) {
            // Decimal alanları veritabanına uygun formata çevir (10,2)
            $decimalFields = [
                'anamiktar', 'bekleyenmiktar', 'bekleyenmiktarhesaplanan', 'birimfiyati',
                'kdv', 'kdvalis', 'kdvsatis', 'kdvsatistoptan', 'kdvtevkifatorani',
                'kdvtevkifattutari', 'kdvtutari', 'kdvtutarisatirdovizi', 'miktar',
                'miktar_rezerv', 'siparisikincibirimmiktar', 'sonbirimfiyati',
                'sonbirimfiyatifisdovizi', 'sontutaryerel', 'teslimatmiktar',
                'teslimedilmeyenmiktar', 'toplambrutagirlik', 'toplambruthacim',
                'toplamnetagirlik', 'toplamnethacim', 'toplamtutar', 'toplamtutarsatirdovizi',
                'tutari', 'tutarisatirdovizi', 'yerelbirimfiyati'
            ];

            foreach ($decimalFields as $field) {
                if ($this->$field !== null) {
                    $this->$field = number_format((float)$this->$field, 2, '.', '');
                }
            }
            
            // Ağırlık otomatik hesaplama: miktar x birim çarpanı x ürün birim ağırlığı (unitkg)
            try {
                $qty = null;
                if ($this->miktar !== null && $this->miktar !== '') {
                    $qty = (float)$this->miktar;
                } elseif ($this->anamiktar !== null && $this->anamiktar !== '') {
                    $qty = (float)$this->anamiktar;
                }

                if ($qty !== null && $qty <= 0) {
                    $this->toplamnetagirlik = number_format(0, 2, '.', '');
                } elseif ($qty !== null && $qty > 0 && !empty($this->kartkodu)) {
                    // Varsayılan çarpan 1; sipariş birimine göre birim çarpanını bul
                    $carpan = 1.0;
                    if (!empty($this->sipbirimi)) {
                        $birim = Birimler::find()->where(['StokKodu' => $this->kartkodu, 'birimkod' => $this->sipbirimi])->one();
                        if ($birim && $birim->carpan !== null && $birim->carpan !== '') {
                            $carpan = (float)$birim->carpan;
                        }
                    }

                    // Ürün birim ağırlığı
                    $urun = Urunler::find()->where(['StokKodu' => $this->kartkodu])->one();
                    if ($urun && $urun->unitkg !== null && $urun->unitkg !== '') {
                        $calculatedNet = (float)$urun->unitkg * $carpan * $qty;
                        $this->toplamnetagirlik = number_format($calculatedNet, 2, '.', '');
                    } else {
                        // Ürün ağırlığı yoksa ve net ağırlık boşsa, brüt ağırlığı kullan (varsa)
                        if (($this->toplamnetagirlik === null || $this->toplamnetagirlik === '' || (float)$this->toplamnetagirlik == 0)
                            && $this->toplambrutagirlik !== null && $this->toplambrutagirlik !== '') {
                            $this->toplamnetagirlik = number_format((float)$this->toplambrutagirlik, 2, '.', '');
                        }
                    }
                }
            } catch (\Throwable $e) {
                // Hata durumunda sessiz geç; istenirse debug log eklenebilir
            }
            
            return true;
        }
        return false;
    }
    public function getTedarikciKey()
    {
        $logFile = Yii::getAlias('@app/runtime/tedarikci_key_debug.log');
        
        if (!$this->siparisler_id) {
            $log = "=== getTedarikciKey() HATA - " . date('Y-m-d H:i:s') . " ===\n";
            $log .= "siparisler_id: " . ($this->siparisler_id ?? 'NULL') . "\n";
            $log .= "kartkodu: " . ($this->kartkodu ?? 'NULL') . "\n";
            $log .= "HATA: siparisler_id bulunamadı\n\n";
            file_put_contents($logFile, $log, FILE_APPEND);
            return null;
        }

        // Siparisler tablosundan fisno'yu al
        $siparis = Siparisler::findOne($this->siparisler_id);
        
        if (!$siparis || !$siparis->fisno) {
            $log = "=== getTedarikciKey() HATA - " . date('Y-m-d H:i:s') . " ===\n";
            $log .= "siparisler_id: " . ($this->siparisler_id ?? 'NULL') . "\n";
            $log .= "kartkodu: " . ($this->kartkodu ?? 'NULL') . "\n";
            $log .= "HATA: siparis bulunamadı veya fisno yok\n";
            if ($siparis) {
                $log .= "fisno değeri: " . ($siparis->fisno ?? 'NULL') . "\n";
            }
            $log .= "\n";
            file_put_contents($logFile, $log, FILE_APPEND);
            return null;
        }
        
        $fisno_from_siparis = trim((string)$siparis->fisno);
        $aranacak_po_id = $fisno_from_siparis;
        
        // Çoklu tedarikçi siparişlerinde fisno sonuna "-1", "-2" gibi bir ek alır.
        // Bu ek, orijinal po_id'yi bulmak için kaldırılmalıdır.
        // Orijinal po_id'de zaten bir tire bulunur (örn: PO-24010101).
        // Bu yüzden tire sayısını kontrol ediyoruz. Birden fazlaysa, son tireden itibaren olan kısmı kırp.
        if (substr_count($fisno_from_siparis, '-') > 1) {
            $lastHyphenPos = strrpos($fisno_from_siparis, '-');
            if ($lastHyphenPos !== false) {
                 $aranacak_po_id = substr($fisno_from_siparis, 0, $lastHyphenPos);
            }
        }
        
        $satinAlmaSiparisFis = SatinAlmaSiparisFis::findOne(['po_id' => $aranacak_po_id]);
        
        if (!$satinAlmaSiparisFis) {
            $log = "=== getTedarikciKey() HATA - " . date('Y-m-d H:i:s') . " ===\n";
            $log .= "siparisler_id: " . ($this->siparisler_id ?? 'NULL') . "\n";
            $log .= "kartkodu: " . ($this->kartkodu ?? 'NULL') . "\n";
            $log .= "fisno (from siparis): " . $siparis->fisno . "\n";
            $log .= "aranan po_id: " . $aranacak_po_id . "\n";
            $log .= "HATA: SatinAlmaSiparisFis bulunamadı\n\n";
            file_put_contents($logFile, $log, FILE_APPEND);
            return null;
        }
        
        // SatinAlmaSiparisFisSatir tablosundan tedarikci_id'yi al
        $siparisSatir = SatinAlmaSiparisFisSatir::find()
            ->where(['siparis_id' => $satinAlmaSiparisFis->id])
            ->andWhere(['StokKodu' => $this->kartkodu])
            ->one();
            
        if (!$siparisSatir || !$siparisSatir->tedarikci_kodu) {
            $log = "=== getTedarikciKey() HATA - " . date('Y-m-d H:i:s') . " ===\n";
            $log .= "siparisler_id: " . ($this->siparisler_id ?? 'NULL') . "\n";
            $log .= "kartkodu: " . ($this->kartkodu ?? 'NULL') . "\n";
            $log .= "satinAlmaSiparisFis->id: " . $satinAlmaSiparisFis->id . "\n";
            $log .= "HATA: siparisSatir bulunamadı veya tedarikci_kodu yok\n";
            if ($siparisSatir) {
                $log .= "tedarikci_kodu değeri: " . ($siparisSatir->tedarikci_kodu ?? 'NULL') . "\n";
            }
            $log .= "\n";
            file_put_contents($logFile, $log, FILE_APPEND);
            return null;
        }
        
        // Tedarikciler tablosundan key'i al
        $tedarikci = Tedarikci::find()->where(['tedarikci_kodu' => $siparisSatir->tedarikci_kodu])->one();
        
        $result = $tedarikci ? $tedarikci->_key : null;
        
        if($result === null){
            $log = "=== getTedarikciKey() HATA - " . date('Y-m-d H:i:s') . " ===\n";
            $log .= "siparisler_id: " . ($this->siparisler_id ?? 'NULL') . "\n";
            $log .= "kartkodu: " . ($this->kartkodu ?? 'NULL') . "\n";
            $log .= "tedarikci_kodu: " . $siparisSatir->tedarikci_kodu . "\n";
            $log .= "HATA: Tedarikçi bulunamadı veya _key'i yok.\n\n";
            file_put_contents($logFile, $log, FILE_APPEND);
        }

        return $result;
    }

}
