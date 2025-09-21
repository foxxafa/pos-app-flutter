<?php

namespace app\models;

use Yii;
use app\components\Dia;
/**
 * This is the model class for table "satiscilar".
 *
 * @property string|null $__format
 * @property string|null $_cdate
 * @property string|null $_date
 * @property int $_key
 * @property int|null $_key_scf_carikart
 * @property int|null $_key_scf_pozisyon
 * @property int|null $_key_sis_depo
 * @property int|null $_key_sis_ozelkod
 * @property int|null $_key_sis_seviyekodu
 * @property int|null $_key_sis_sube
 * @property int|null $_level1
 * @property int|null $_level2
 * @property int|null $_owner
 * @property int|null $_serial
 * @property int|null $_user
 * @property string|null $aciklama
 * @property string|null $carikodu
 * @property string|null $cariunvan
 * @property string|null $ceptel
 * @property string|null $durum
 * @property string|null $ekleyenkullaniciadi
 * @property string|null $eposta
 * @property string|null $isyerikredikartlari
 * @property string|null $kodu
 * @property string|null $kullaniciadi
 * @property float|null $maxindirimorani
 * @property string|null $ozelkodu
 * @property string|null $pozisyon
 */
class Satiscilar extends \yii\db\ActiveRecord
{


    /**
     * {@inheritdoc}
     */
    public static function tableName()
    {
        return 'satiscilar';
    }

    /**
     * {@inheritdoc}
     */
    public function rules()
    {
        return [
            [['__format', '_cdate', '_date', '_key_scf_carikart', '_key_scf_pozisyon', '_key_sis_depo', '_key_sis_ozelkod', '_key_sis_seviyekodu', '_key_sis_sube', '_level1', '_level2', '_owner', '_serial', '_user', 'aciklama', 'carikodu', 'cariunvan', 'ceptel', 'durum', 'ekleyenkullaniciadi', 'eposta', 'isyerikredikartlari', 'kodu', 'kullaniciadi', 'maxindirimorani', 'ozelkodu', 'pozisyon'], 'default', 'value' => null],
            [['_cdate', '_date'], 'safe'],
            [['_key'], 'required'],
            [['_key', '_key_scf_carikart', '_key_scf_pozisyon', '_key_sis_depo', '_key_sis_ozelkod', '_key_sis_seviyekodu', '_key_sis_sube', '_level1', '_level2', '_owner', '_serial', '_user'], 'integer'],
            [['isyerikredikartlari'], 'string'],
            [['maxindirimorani'], 'number'],
            [['__format'], 'string', 'max' => 10],
            [['aciklama', 'cariunvan', 'eposta'], 'string', 'max' => 255],
            [['carikodu', 'ekleyenkullaniciadi', 'kodu', 'kullaniciadi', 'ozelkodu', 'pozisyon'], 'string', 'max' => 100],
            [['ceptel'], 'string', 'max' => 20],
            [['durum'], 'string', 'max' => 1],
            [['password'], 'string', 'max' => 40],
            [['_key'], 'unique'],
        ];
    }

    /**
     * {@inheritdoc}
     */
    public function attributeLabels()
    {
        return [
            '__format' => 'Format',
            '_cdate' => 'Cdate',
            '_date' => 'Date',
            '_key' => 'Key',
            '_key_scf_carikart' => 'Key Scf Carikart',
            '_key_scf_pozisyon' => 'Key Scf Pozisyon',
            '_key_sis_depo' => 'Key Sis Depo',
            '_key_sis_ozelkod' => 'Key Sis Ozelkod',
            '_key_sis_seviyekodu' => 'Key Sis Seviyekodu',
            '_key_sis_sube' => 'Key Sis Sube',
            '_level1' => 'Level1',
            '_level2' => 'Level2',
            '_owner' => 'Owner',
            '_serial' => 'Serial',
            '_user' => 'User',
            'aciklama' => 'Aciklama',
            'carikodu' => 'Carikodu',
            'cariunvan' => 'Cariunvan',
            'ceptel' => 'Ceptel',
            'durum' => 'Durum',
            'ekleyenkullaniciadi' => 'Ekleyenkullaniciadi',
            'eposta' => 'Eposta',
            'isyerikredikartlari' => 'Isyerikredikartlari',
            'kodu' => 'Kodu',
            'kullaniciadi' => 'Kullaniciadi',
            'maxindirimorani' => 'Maxindirimorani',
            'ozelkodu' => 'Ozelkodu',
            'pozisyon' => 'Pozisyon',
        ];
    }
    public static function importFromApi()
    {
        $data = Dia::getSatiscilar();
        if (!isset($data['result']) || !is_array($data['result'])) {
            throw new \Exception('Geçersiz veri formatı');
        }

        $inserted = 0;
        $updated = 0;

        foreach ($data['result'] as $item) {
            if (!isset($item['_key'])) {
                continue;
            }

            $model = self::findOne(['_key' => $item['_key']]);
            if (!$model) {
                $model = new self();
                $inserted++;
            } else {
                $updated++;
            }

            // Model alanlarını ata
            foreach ($item as $field => $value) {
                if ($model->hasAttribute($field)) {
                    $model->$field = $value;
                }
            }

            $model->save(false); // false → validate etmeden kaydet
        }

        return ['inserted' => $inserted, 'updated' => $updated];
    }

}
