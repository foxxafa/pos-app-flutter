<?php

namespace app\models;

use Yii;
use yii\db\ActiveRecord;
use app\models\SiparislerAyrintili;
use app\models\Musteriler;

/**
 * This is the model class for table "siparisler".
 *
 * @property int $id
 * @property string|null $__sourcesubeadi
 * @property string|null $subekodu
 * @property string|null $__sourcedepoadi
 * @property string|null $depokodu
 * @property string|null $__format
 * @property string|null $_cdate
 * @property string|null $_date
 * @property string|null $_key
 * @property string|null $_key_satiselemanlari
 * @property string|null $__carikodu

 * @property string|null $_key_scf_satiselemani
 * @property string|null $_key_sis_firma
 * @property int|null $_owner
 * @property string|null $_user
 * @property string|null $aciklama
 * @property string|null $_serial
 * @property string|null $aciklama2
 * @property string|null $aciklama3
 * @property string|null $adsoyad
 * @property string|null $ekleyenkullaniciadi
 * @property string|null $fisno
 * @property string|null $gorusmenotu
 * @property string|null $kargofirma
 * @property string|null $kargogonderimsaati
 * @property string|null $kargogonderimtarihi
 * @property string|null $kullaniciadi
 * @property float|null $net
 * @property float|null $netdvz
 * @property float|null $odenen_tutar
 * @property string|null $onay
 * @property string|null $onay_txt
 * @property string|null $satiselemani
 * @property string|null $sevkadresi
 * @property string|null $sevkadresi1
 * @property string|null $sevkadresi2
 * @property string|null $sevkadresi3
 * @property string|null $sevkadresi_adi
 * @property string|null $siparisdurum
 * @property string|null $sipariskalemturleri
 * @property string|null $sipteslimattarihi
 * @property string|null $tamamisevkedildi
 * @property string|null $tarih
 * @property string|null $teslimat_adres1
 * @property string|null $teslimat_adsoyad
 * @property float|null $teslimatkalanmiktar
 * @property float|null $teslimatmiktar
 * @property string|null $teslimattarihi
 * @property float|null $toplam
 * @property float|null $toplamanamiktar
 * @property float|null $toplamara
 * @property float|null $toplamaradvz
 * @property float|null $toplamdvz
 * @property float|null $toplamindirim
 * @property float|null $toplamindirimdvz
 * @property float|null $toplamkdv
 * @property float|null $toplamkdvdvz
 * @property float|null $toplamkdvtevkifati
 * @property float|null $toplamkdvtevkifatidvz
 * @property float|null $toplammasraf
 * @property float|null $toplammasrafdvz
 * @property float|null $toplammiktar
 * @property float|null $toplammiktarrafyerli
 * @property float|null $toplamov
 * @property float|null $toplamovdvz
 * @property string|null $turu
 * @property string|null $turuack
 * @property int|null $delivery_id
 * @property string|null $_key_sis_sube_source
 * @property string|null $_key_sis_depo_source
 */
class Siparisler extends \yii\db\ActiveRecord
{
    /**
     * {@inheritdoc}
     */
    public static function tableName()
    {
        return 'siparisler';
    }

    /**
     * {@inheritdoc}
     */
    public function rules()
    {
        return [
            [['_cdate', '_date', 'tarih', 'delivery_id'], 'safe'],
            [['_owner', 'delivery_id'], 'integer'],
            [['net', 'netdvz', 'odenen_tutar', 'teslimatkalanmiktar', 'teslimatmiktar', 'toplam', 'toplamanamiktar', 'toplamara', 'toplamaradvz', 'toplamdvz', 'toplamindirim', 'toplamindirimdvz', 'toplamkdv', 'toplamkdvdvz', 'toplamkdvtevkifati', 'toplamkdvtevkifatidvz', 'toplammasraf', 'toplammasrafdvz', 'toplammiktar', 'toplammiktarrafyerli', 'toplamov', 'toplamovdvz'], 'number'],
            [['aciklama', 'aciklama2', 'aciklama3', 'gorusmenotu', 'sevkadresi'], 'string', 'max' => 255],
            [['__sourcesubeadi', '_user', 'ekleyenkullaniciadi', 'kullaniciadi', 'onay_txt', 'satiselemani', 'sevkadresi_adi', 'siparisdurum', 'turuack'], 'string', 'max' => 50],
            [['__sourcedepoadi', '__format', '_key_satiselemanlari', '_key_scf_satiselemani'], 'string', 'max' => 50],
            [['_key', '__carikodu', '_key_sis_firma', 'subekodu', 'depokodu'], 'string', 'max' => 30],
            [['_serial', 'sevkadresi1', 'sevkadresi2', 'sevkadresi3', 'teslimat_adres1', 'teslimat_adsoyad'], 'string', 'max' => 100],
            [['adsoyad', 'kargofirma'], 'string', 'max' => 100],
            [['fisno'], 'string', 'max' => 20],
            [['kargogonderimsaati', 'kargogonderimtarihi', 'onay', 'sipteslimattarihi', 'teslimattarihi'], 'string', 'max' => 20],
            [['tamamisevkedildi'], 'string', 'max' => 1],
            [['sipariskalemturleri', 'turu'], 'string', 'max' => 10],
            [['_key_sis_sube_source', '_key_sis_depo_source'], 'string', 'max' => 15],
        ];
    }

    /**
     * {@inheritdoc}
     */
    public function attributeLabels()
    {
        return [
            'id' => 'ID',
            '__sourcesubeadi' => 'Source Branch Name',
            'subekodu' => 'Branch Code',
            '__sourcedepoadi' => 'Source Depot Name',
            'depokodu' => 'Depot Code',
            '__format' => 'Format',
            '_cdate' => 'Creation Date',
            '_date' => 'Date',
            '_key' => 'Key',
            '_key_satiselemanlari' => 'Salesman Key',
            '__carikodu' => 'Customer Code',
            '_key_scf_satiselemani' => 'Salesman Key',
            '_key_sis_firma' => 'Firma Key',
            '_owner' => 'Owner',
            '_user' => 'User',
            'aciklama' => 'Description',
            '_serial' => 'Serial',
            'aciklama2' => 'Description 2',
            'aciklama3' => 'Description 3',
            'adsoyad' => 'Name Surname',
            'ekleyenkullaniciadi' => 'Created By',
            'fisno' => 'Receipt No',
            'gorusmenotu' => 'Meeting Note',
            'kargofirma' => 'Carrier',
            'kargogonderimsaati' => 'Carrier Delivery Time',
            'kargogonderimtarihi' => 'Carrier Delivery Date',
            'kullaniciadi' => 'User',
            'net' => 'Net',
            'netdvz' => 'Net Currency',
            'odenen_tutar' => 'Paid Amount',
            'onay' => 'Approved',
            'onay_txt' => 'Approved Description',
            'satiselemani' => 'Salesman',
            'sevkadresi' => 'Delivery Address',
            'sevkadresi1' => 'Delivery Address 1',
            'sevkadresi2' => 'Delivery Address 2',
            'sevkadresi3' => 'Delivery Address 3',
            'sevkadresi_adi' => 'Delivery Address Name',
            'siparisdurum' => 'Order Status',
            'sipariskalemturleri' => 'Order Item Types',
            'sipteslimattarihi' => 'Order Delivery Date',
            'tamamisevkedildi' => 'All Delivered',
            'tarih' => 'Date',
            'teslimat_adres1' => 'Delivery Address 1',
            'teslimat_adsoyad' => 'Delivery Address Name',
            'teslimatkalanmiktar' => 'Delivery Remaining Amount',
            'teslimatmiktar' => 'Delivery Amount',
            'teslimattarihi' => 'Delivery Date',
            'toplam' => 'Total',
            'toplamanamiktar' => 'Total Main Amount',
            'toplamara' => 'Total Sub Amount',
            'toplamaradvz' => 'Total Sub Currency',
            'toplamdvz' => 'Total Currency',
            'toplamindirim' => 'Total Discount',
            'toplamindirimdvz' => 'Total Discount Currency',
            'toplamkdv' => 'Total Tax',
            'toplamkdvdvz' => 'Total Tax Currency',
            'toplamkdvtevkifati' => 'Total Tax Exemption',
            'toplamkdvtevkifatidvz' => 'Total Tax Exemption Currency',
            'toplammasraf' => 'Total Expense',
            'toplammasrafdvz' => 'Total Expense Currency',
            'toplammiktar' => 'Total Amount',
            'toplammiktarrafyerli' => 'Total Amount Local',
            'toplamov' => 'Total VAT',
            'toplamovdvz' => 'Total VAT Currency',
            'turu' => 'Type',
            'turuack' => 'Type Description',
            'delivery_id' => 'Delivery ID',
            '_key_sis_sube_source' => 'SIS Branch Source Key',
            '_key_sis_depo_source' => 'SIS Depot Source Key',
        ];
    }

    public function getMusteri()
    {
        return $this->hasOne(Musteriler::class, ['Kod' => '__carikodu']);
    }

    public static function getSiparisAgirlik($fisno = null){
        if ($fisno === null) {
            $fisno = Yii::$app->request->get('fisno');
        }
        
        $siparis = self::findOne(['fisno'=>$fisno]);
        if (!$siparis) {
            return 0;
        }
        
        $toplamAgirlik = SiparislerAyrintili::find()
            ->where(['fisno' => $siparis->fisno])
            ->sum('toplamnetagirlik');
            
        // Format to 2 decimal places
        return number_format((float)($toplamAgirlik ?? 0), 2, '.', '');
    }
}