<?php

namespace app\models;

use Yii;

/**
 * This is the model class for table "important_days".
 *
 * @property int $id
 * @property string $name Önemli günün veya dönemin adı
 * @property string $start_date Başlangıç tarihi
 * @property string|null $end_date Bitiş tarihi (boş ise tek günlük bir olaydır)
 * @property string|null $description Açıklama
 * @property string|null $created_at
 * @property string|null $updated_at
 */
class ImportantDays extends \yii\db\ActiveRecord
{


    /**
     * {@inheritdoc}
     */
    public static function tableName()
    {
        return 'important_days';
    }

    /**
     * {@inheritdoc}
     */
    public function rules()
    {
        return [
            [['end_date', 'description'], 'default', 'value' => null],
            [['name', 'start_date'], 'required'],
            [['start_date', 'end_date', 'created_at', 'updated_at'], 'safe'],
            [['start_date'], 'match', 'pattern' => '/^\d{2}\.\d{2}\.\d{4}$/', 'message' => 'Tarih gg.aa.yyyy formatında olmalıdır.'],
            [['end_date'], 'match', 'pattern' => '/^\d{2}\.\d{2}\.\d{4}$/', 'skipOnEmpty' => true, 'message' => 'Tarih gg.aa.yyyy formatında olmalıdır.'],
            [['start_date', 'end_date'], 'validateDottedDate'],
            [['description'], 'string'],
            [['name'], 'string', 'max' => 255],
        ];
    }

    /**
     * {@inheritdoc}
     */
    public function attributeLabels()
    {
        return [
            'id' => 'ID',
            'name' => 'Name',
            'start_date' => 'Start Date',
            'end_date' => 'End Date',
            'description' => 'Description',
            'created_at' => 'Created At',
            'updated_at' => 'Updated At',
        ];
    }

    /**
     * dd.mm.yyyy tarih girişini doğrular ve geçersizse hata ekler.
     * Y-m-d veya boş değerleri es geçer (diğer kod yolları için tolerans).
     */
    public function validateDottedDate($attribute)
    {
        $value = $this->$attribute;
        if ($value === null || $value === '') {
            return;
        }
        // Zaten ISO gelmişse doğrulamayı atla
        if (preg_match('/^\d{4}-\d{2}-\d{2}$/', (string)$value)) {
            return;
        }
        if (!preg_match('/^\d{2}\.\d{2}\.\d{4}$/', (string)$value)) {
            $this->addError($attribute, 'Tarih gg.aa.yyyy formatında olmalıdır.');
            return;
        }
        $dt = \DateTime::createFromFormat('d.m.Y', (string)$value);
        $errors = \DateTime::getLastErrors();
        $warningCount = is_array($errors) ? (int)($errors['warning_count'] ?? 0) : 0;
        $errorCount = is_array($errors) ? (int)($errors['error_count'] ?? 0) : 0;
        if ($dt === false || $warningCount > 0 || $errorCount > 0) {
            $this->addError($attribute, 'Geçerli bir tarih giriniz.');
        }
    }

    /**
     * Kayıt öncesi dd.mm.yyyy biçimini Y-m-d biçimine çevirir.
     */
    public function beforeSave($insert)
    {
        if (!parent::beforeSave($insert)) {
            return false;
        }
        $this->start_date = $this->normalizeDottedDateToIso($this->start_date);
        $this->end_date = $this->normalizeDottedDateToIso($this->end_date);
        return true;
    }

    private function normalizeDottedDateToIso($value)
    {
        if ($value === null || $value === '') {
            return $value;
        }
        $stringValue = (string)$value;
        // Zaten ISO ise dokunma
        if (preg_match('/^\d{4}-\d{2}-\d{2}$/', $stringValue)) {
            return $stringValue;
        }
        if (preg_match('/^\d{2}\.\d{2}\.\d{4}$/', $stringValue)) {
            $dt = \DateTime::createFromFormat('d.m.Y', $stringValue);
            if ($dt instanceof \DateTime) {
                return $dt->format('Y-m-d');
            }
        }
        return $stringValue;
    }
}
